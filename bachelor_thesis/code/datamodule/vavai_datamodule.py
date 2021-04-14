import pandas as pd
import numpy as np
import pickle
import os
from typing import Optional
import torch
import torchtext
from torch.nn.utils.rnn import pad_sequence
from torchtext.data.utils import get_tokenizer
from collections import Counter
from torchtext.vocab import Vocab
from torch.utils.data import Dataset, DataLoader, random_split, Subset
from pytorch_lightning import LightningDataModule
from torch.utils.data.dataset import T_co
import scipy.sparse

from datamodule.utils import ConvertToBagOfWords, replace_nan_drop_empty

DATA_DIR = os.path.join('/home/fassty/Devel/mff/bachelor_thesis/code/data', 'vae_processed')
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
            selected_columns = selected_columns[:5000]

            for transform in transforms.values():
                selected_columns = transform(selected_columns)

            selected_columns.reset_index(inplace=True)
            selected_columns.drop(columns='index', inplace=True)
            self.vocab = sorted(list(set(' '.join(selected_columns['input'].apply(' '.join)).split() + ['<eos>'])))
            self.word2index = dict()
            self.index2word = dict()
            for index, word in enumerate(self.vocab):
                self.word2index[word] = index
                self.index2word[index] = word

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
            self.seq_len = self.data[0][0].shape[0]

            with open(W2I_PATH, 'rb') as handle:
                self.word2index = pickle.load(handle)
            with open(I2W_PATH, 'rb') as handle:
                self.index2word = pickle.load(handle)

    def _coo_to_tensor(self, coo: scipy.sparse.coo_matrix):
        values = torch.FloatTensor(coo.data)
        indices = torch.LongTensor(np.vstack((coo.row, coo.col)))
        shape = coo.shape
        tensor = torch.sparse_coo_tensor(indices, values, torch.Size(shape))
        return tensor

    def __getitem__(self, index) -> T_co:
        input_ = self._coo_to_tensor(self.data[index, 0]).to_dense()
        target = self._coo_to_tensor(self.data[index, 1]).to_dense()
        length = torch.tensor(self.data[index, 2], dtype=torch.int32)

        return input_, target, length

    def __len__(self):
        return len(self.data)

    def get_index(self, word):
        return self.word2index[word]

    def get_word(self, index):
        return self.index2word[index]

    @property
    def vocab_size(self):
        return len(self.vocab)

    @property
    def pad_idx(self):
        return self.word2index['<pad>']

    @property
    def sos_idx(self):
        return self.word2index['<sos>']

    @property
    def eos_idx(self):
        return self.word2index['<eos>']


class VaVaITorchTextDataset(Dataset):
    def __init__(
            self,
            csv_file: str,
            columns: list
    ):
        csv_data = pd.read_csv(csv_file)
        selected_columns = csv_data.iloc[:, columns]
        selected_columns = replace_nan_drop_empty(selected_columns, '')
        selected_columns = selected_columns.apply(' '.join, axis=1)
        selected_columns = selected_columns.iloc[:1000]

        counter = Counter()
        tokenizer = get_tokenizer('spacy', language='en')

        for string_ in selected_columns:
            counter.update(tokenizer(string_))

        vavai_vocab = Vocab(counter, specials=['<unk>', '<pad>', '<sos>', '<eos>'])

        raw_data_iter = iter(selected_columns)
        data = []
        for raw_data in raw_data_iter:
            tensor_ = torch.tensor([vavai_vocab[token] for token in tokenizer(raw_data)],
                                   dtype=torch.long)
            data.append((tensor_, tensor_))

        self.data = data
        self.vocab = vavai_vocab

    def __getitem__(self, item):
        return self.data[item]

    def __len__(self):
        return len(self.data)

    @property
    def vocab_size(self):
        return len(self.vocab)

    @property
    def pad_idx(self):
        return self.vocab['<pad>']

    @property
    def sos_idx(self):
        return self.vocab['<sos>']

    @property
    def eos_idx(self):
        return self.vocab['<eos>']

    def generate_batch(self, data_batch):
        input_batch, target_batch = [], []
        for (input_item, target_item) in data_batch:
            input_batch.append(torch.cat([torch.tensor([self.sos_idx]), input_item,
                                          torch.tensor([self.eos_idx])], dim=0))
            target_batch.append(torch.cat([torch.tensor([self.sos_idx]), target_item,
                                           torch.tensor([self.eos_idx])], dim=0))
        input_batch = pad_sequence(input_batch, padding_value=self.pad_idx)
        target_batch = pad_sequence(target_batch, padding_value=self.pad_idx)
        return input_batch, target_batch


class VaVaIDataModule(LightningDataModule):
    def __init__(self, dataset, batch_size):
        super().__init__()
        self.dataset = dataset
        self.batch_size = batch_size
        self.collate_fn = dataset.generate_batch if hasattr(dataset, 'generate_batch') else None
        self.train_split = None
        self.val_split = None
        self.test_split = None

    def prepare_data(self, *args, **kwargs):
        pass

    def setup(self, stage: Optional[str] = None):
        train = int(len(self.dataset) * 0.8)
        val = (len(self.dataset) - train) // 2
        test = len(self.dataset) - (val + train)
        self.train_split, self.val_split, self.test_split = random_split(self.dataset, [train, val, test])

    def train_dataloader(self):
        data_loader = DataLoader(self.train_split, batch_size=self.batch_size, num_workers=4, shuffle=True,
                                 collate_fn=self.collate_fn)
        return data_loader

    def val_dataloader(self):
        data_loader = DataLoader(self.val_split, batch_size=self.batch_size, num_workers=4, shuffle=False,
                                 collate_fn=self.collate_fn)
        return data_loader

    def test_dataloader(self):
        data_loader = DataLoader(self.test_split, batch_size=self.batch_size, num_workers=4, shuffle=False,
                                 collate_fn=self.collate_fn)
        return data_loader
