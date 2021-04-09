import pandas as pd
import numpy as np
import pickle
import os
from typing import Optional
import torch
from torch.utils.data import Dataset, DataLoader, random_split, Subset
from pytorch_lightning import LightningDataModule
from torch.utils.data.dataset import T_co
import scipy.sparse

from datamodule.utils import ConvertToBagOfWords, replace_nan_drop_empty

DATA_DIR = os.path.join('data', 'vae_processed')
PROCESSED_DATA_PATH = os.path.join(DATA_DIR, 'processed_data.npy')
VOCAB_PATH = os.path.join(DATA_DIR, 'vocab.npy')
W2I_PATH = os.path.join(DATA_DIR, 'word2index.pickle')
I2W_PATH = os.path.join(DATA_DIR, 'index2word.pickle')

class VaVaIOneHotDataSet(Dataset):
    """
    0  - Kód projektu
    1  - Název česky
    2  - Název anglicky
    3  - Anotace česky
    4  - Anotace anglicky
    5  - Hlavní CEP obor
    6  - Vedlejší CEP obor
    7  - Další vedlejší CEP obor
    8  - Hlavní FORD obor
    9  - Vedlejší FORD obor
    10 - Další vedlejší FORD obor
    11 - Kategorie VaV
    12 - Hlavní účastníci
    13 - Další účastníci
    14 - Výčet právních forem účastníků
    15 - Výčet krajů účastníků
    16 - Výčet zemí účastníků
    17 - Podrobné informace o účastnících
    18 - Hlavní řešitelé
    19 - Další řešitelé
    20 - Klíčová slova
    21 - Výčet druhů dosažených výsledků
    22 - Poskytovatel
    23 - Program
    24 - Uznané náklady
    25 - Podpora ze SR
    26 - Ostatní veřejné zdroje fin.
    27 - Neveřejné zdroje fin.
    28 - Začátek řešení
    29 - Konec řešení
    30 - URL v Starfose
    31 - Relevance
    """
    def __init__(
            self,
            csv_file: str,
            columns: list,
            transforms: list
    ):
        if not os.path.exists(PROCESSED_DATA_PATH)\
                or not os.path.exists(VOCAB_PATH) \
                or not os.path.exists(W2I_PATH) \
                or not os.path.exists(I2W_PATH):
            data = pd.read_csv(csv_file)
            selected_columns = data.iloc[:, columns]
            selected_columns = replace_nan_drop_empty(selected_columns, '')
            selected_columns = selected_columns.apply(' '.join, axis=1)
            selected_columns = selected_columns.iloc[:500]

            for transform in transforms:
                selected_columns = transform(selected_columns)

            selected_columns.reset_index(inplace=True)
            selected_columns.drop(columns='index', inplace=True)
            self.vocab = sorted(list(set(' '.join(selected_columns['input'].apply(' '.join)).split() + ['<eos>'])))
            self.vocab_size = len(self.vocab)
            self.word2index = dict()
            self.index2word = dict()
            for index, word in enumerate(self.vocab):
                self.word2index[word] = index
                self.index2word[index] = word

            self.sos_idx = self.word2index['<sos>']
            self.eos_idx = self.word2index['<eos>']
            self.pad_idx = self.word2index['<pad>']

            selected_columns = ConvertToBagOfWords()(selected_columns, self.word2index)
            self.data = selected_columns
            self.seq_len = self.data[0][0].shape[0]
            np.save(PROCESSED_DATA_PATH, self.data)
            np.save(VOCAB_PATH, np.array(self.vocab))

            with open(W2I_PATH, 'wb') as handle:
                pickle.dump(self.word2index, handle, protocol=pickle.HIGHEST_PROTOCOL)
            with open(I2W_PATH, 'wb') as handle:
                pickle.dump(self.index2word, handle, protocol=pickle.HIGHEST_PROTOCOL)
        else:
            self.data = np.load(PROCESSED_DATA_PATH, allow_pickle=True)
            self.vocab = np.load(VOCAB_PATH, allow_pickle=True)
            self.vocab_size = len(self.vocab)
            self.seq_len = self.data[0][0].shape[0]

            with open(W2I_PATH, 'rb') as handle:
                self.word2index = pickle.load(handle)
            with open(I2W_PATH, 'rb') as handle:
                self.index2word = pickle.load(handle)

            self.sos_idx = self.word2index['<sos>']
            self.eos_idx = self.word2index['<eos>']
            self.pad_idx = self.word2index['<pad>']

    def _coo_to_tensor(self, coo: scipy.sparse.coo_matrix):
        values = torch.FloatTensor(coo.data)
        indices = torch.LongTensor(np.vstack((coo.row, coo.col)))
        shape = coo.shape
        tensor = torch.sparse_coo_tensor(indices, values, torch.Size(shape))
        return tensor

    def __getitem__(self, index) -> T_co:
        index = index.item()

        input = self._coo_to_tensor(self.data[index, 0]).to_dense()
        target = self._coo_to_tensor(self.data[index, 1]).to_dense()
        length = torch.tensor(self.data[index, 2], dtype=torch.int32)

        return input, target, length

    def __len__(self):
        return len(self.data)


class VaVaIDataModule(LightningDataModule):
    def __init__(self, dataset=None):
        super().__init__()
        self.dataset = dataset
        self.train_split = None
        self.val_split = None
        self.test_split = None

    def prepare_data(self, *args, **kwargs):
        pass

    def setup(self, stage: Optional[str] = None):
        indices = torch.randperm(500)
        dataset = Subset(self.dataset, indices)
        self.train_split, self.val_split, self.test_split = random_split(dataset, [400, 50, 50])

    def train_dataloader(self):
        return DataLoader(self.train_split, batch_size=8, num_workers=4, shuffle=True)

    def val_dataloader(self):
        return DataLoader(self.val_split, batch_size=8, num_workers=4, shuffle=False)

    def test_dataloader(self):
        return DataLoader(self.test_split, batch_size=8, num_workers=4, shuffle=False)
