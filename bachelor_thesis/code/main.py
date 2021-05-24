import pytorch_lightning as pl
from hydra.utils import instantiate
from omegaconf import DictConfig
import torch
import numpy as np

from datamodule.vavai_datamodule import VaVaIDataModule, VaVaIOneHotDataSet, VaVaITorchTextDataset
from models.attn import AttnAE
from models.vae import VAE
from datamodule.utils import RemoveAccents, RemoveStopwords, Lemmatize, TrimSentences, PadSentences, ConvertToBagOfWords
import hydra


def train_vae():
    dataset = VaVaIOneHotDataSet(csv_file='../data/TACR_Starfos_isvav_project.csv',
                                 columns=[20],
                                 num_samples=100,
                                 transforms=[
                                     RemoveAccents(),
                                     Lemmatize(),
                                     RemoveStopwords(),
                                     TrimSentences(max_len=100),
                                     PadSentences(pad_with='<pad>')
                                 ])
    datamodule = VaVaIDataModule(dataset=dataset, batch_size=32)

    model = VAE(input_dim=dataset.vocab_size,
                hidden_dim=256,
                latent_dim=20,
                seq_len=dataset.seq_len,
                cell_type='lstm',
                n_layers=1,
                bidirectional=True,
                index2word=dataset.index2word,
                word2index=dataset.word2index)

    checkpoint_callback = pl.callbacks.ModelCheckpoint(monitor='val_accuracy',
                                                       filename='RVAE-{epoch:02d}-{val_accuracy:.2f}',
                                                       save_top_k=3,
                                                       mode='max')

    checkpoint_path = 'lightning_logs/rvae_kwords_0.13_acc/checkpoints/RVAE-epoch=07-val_accuracy=0.13.ckpt'
    trainer = pl.Trainer(callbacks=[checkpoint_callback], log_every_n_steps=1, max_epochs=10, resume_from_checkpoint=checkpoint_path)
    trainer.fit(model, datamodule=datamodule)


def train_attn():
    dataset = VaVaITorchTextDataset(csv_file='../data/TACR_Starfos_isvav_project.csv',
                                    columns=[20],
                                    field='EB - Genetika a molekulární biologie')
    module = VaVaIDataModule(dataset, batch_size=32)

    model = AttnAE(input_dim=len(dataset.vocab),
                   output_dim=len(dataset.vocab),
                   embedding_dim=50,
                   hidden_dim=256,
                   attention_dim=64,
                   dropout=0.3,
                   pad_idx=dataset.vocab.stoi['<pad>'],
                   vocab=dataset.vocab)

    checkpoint_callback = pl.callbacks.ModelCheckpoint(monitor='val_acc',
                                                       filename='AttnAE-{epoch:02d}-{val_acc:.2f}',
                                                       save_top_k=3,
                                                       mode='max')
    checkpoint_path = 'lightning_logs/attn_ae_all_kwords_shortrun/checkpoints/AttnAE-epoch=02-val_loss=6.30.ckpt'
    trainer = pl.Trainer(callbacks=[checkpoint_callback], max_epochs=250, resume_from_checkpoint=checkpoint_path)
    trainer.fit(model, datamodule=module)


def predict():
    dataset = VaVaITorchTextDataset(csv_file='../data/TACR_Starfos_isvav_project.csv',
                                    columns=[20],
                                    field=-1)

    model = AttnAE.load_from_checkpoint('lightning_logs/attn_ae_all_kwords_54acc/checkpoints/AttnAE-epoch=22-val_acc=0.54.ckpt',
                                        pad_idx=dataset.vocab.stoi['<pad>'], vocab=dataset.vocab)

    embeddings = []
    for i in range(len(dataset)):
        prediction = model.encoder.embedding(dataset[i][0].unsqueeze(0))
        prediction = prediction.squeeze(0)
        embedding = torch.mean(prediction, dim=0).detach()
        embeddings.append(embedding.numpy())
    embeddings = np.array(embeddings)
    np.save('vectors.npy', embeddings)

# TODO: use Hydra to setup experiments
# @hydra.main(config_name='config.yaml', config_path='config/')
def main():
    #train_vae()
    train_attn()
    #predict()


if __name__ == '__main__':
    main()
