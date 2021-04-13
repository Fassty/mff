import pytorch_lightning as pl
from datamodule.vavai_datamodule import VaVaIDataModule, VaVaIOneHotDataSet, VaVaITorchTextDataset
from models.seq2seq import AttnAE
from models.vae import VAE
from datamodule.utils import RemoveAccents, RemoveStopwords, Lemmatize, TrimSentences, PadSentences, ConvertToBagOfWords


def main():
    # dataset = VaVaIOneHotDataSet(csv_file='data/TACR_Starfos_isvav_project.csv',
    #                              columns=[2, 4],
    #                              transforms=[
    #                                  RemoveAccents(),
    #                                  Lemmatize(),
    #                                  RemoveStopwords(),
    #                                  TrimSentences(max_len=32),
    #                                  PadSentences(pad_with='<pad>')
    #                              ])
    # datamodule = VaVaIDataModule(dataset=dataset)
    #
    # model = VAE(input_dim=dataset.vocab_size,
    #             hidden_dim=256,
    #             latent_dim=100,
    #             seq_len=dataset.seq_len,
    #             cell_type='lstm',
    #             n_layers=1,
    #             bidirectional=True,
    #             index2word=dataset.index2word,
    #             word2index=dataset.word2index)
    #
    # trainer = pl.Trainer(gpus=-1)
    # trainer.fit(model, datamodule=datamodule)
    dataset = VaVaITorchTextDataset(csv_file='data/TACR_Starfos_isvav_project.csv', columns=[2, 4])
    module = VaVaIDataModule(dataset, batch_size=16)

    model = AttnAE(input_dim=len(dataset.vocab),
                   output_dim=len(dataset.vocab),
                   embedding_dim=32,
                   hidden_dim=64,
                   attention_dim=8,
                   dropout=0.5,
                   pad_idx=dataset.vocab.stoi['<pad>'])

    trainer = pl.Trainer()
    trainer.fit(model, datamodule=module)


if __name__ == '__main__':
    main()
