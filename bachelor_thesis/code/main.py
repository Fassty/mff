import pytorch_lightning as pl
from datamodule.vavai_datamodule import VaVaIDataModule, VaVaIOneHotDataSet
from models.vae import VAE
from datamodule.utils import RemoveAccents, RemoveStopwords, Lemmatize, TrimSentences, PadSentences, ConvertToBagOfWords


def main():
    dataset = VaVaIOneHotDataSet(csv_file='~/Devel/mff/bachelor_thesis/data/TACR_Starfos_isvav_project.csv',
                                 columns=[2, 4, 20],
                                 transforms=[
                                     RemoveAccents(),
                                     Lemmatize(),
                                     RemoveStopwords(),
                                     TrimSentences(max_len=32),
                                     PadSentences(pad_with='<pad>')
                                 ])
    datamodule = VaVaIDataModule(dataset=dataset)

    model = VAE(input_dim=dataset.vocab_size,
                hidden_dim=128,
                latent_dim=100,
                seq_len=dataset.seq_len,
                cell_type='lstm',
                n_layers=1,
                bidirectional=False,
                index2word=dataset.index2word,
                word2index=dataset.word2index)

    trainer = pl.Trainer()
    trainer.fit(model, datamodule=datamodule)


if __name__ == '__main__':
    main()
