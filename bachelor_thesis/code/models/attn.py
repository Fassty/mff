import random
from typing import Tuple

import torch
import torch.nn as nn
import torch.optim as optim
import torch.nn.functional as F
from pytorch_lightning import LightningModule
from torch import Tensor
import torchmetrics


class Encoder(nn.Module):
    def __init__(self,
                 input_dim: int,
                 emb_dim: int,
                 enc_hid_dim: int,
                 dec_hid_dim: int,
                 dropout: float):
        super().__init__()

        self.input_dim = input_dim
        self.emb_dim = emb_dim
        self.enc_hid_dim = enc_hid_dim
        self.dec_hid_dim = dec_hid_dim
        self.dropout = dropout

        self.embedding = nn.Embedding(input_dim, emb_dim)

        self.rnn = nn.GRU(emb_dim, enc_hid_dim, bidirectional=True)

        self.fc = nn.Linear(enc_hid_dim * 2, dec_hid_dim)

        self.dropout = nn.Dropout(dropout)

    def forward(self,
                src: Tensor) -> Tuple[Tensor]:

        embedded = self.dropout(self.embedding(src))

        outputs, hidden = self.rnn(embedded)

        hidden = torch.tanh(self.fc(torch.cat((hidden[-2, :, :], hidden[-1, :, :]), dim=1)))

        return outputs, hidden


class Attention(nn.Module):
    def __init__(self,
                 enc_hid_dim: int,
                 dec_hid_dim: int,
                 attn_dim: int):
        super().__init__()

        self.enc_hid_dim = enc_hid_dim
        self.dec_hid_dim = dec_hid_dim

        self.attn_in = (enc_hid_dim * 2) + dec_hid_dim

        self.attn = nn.Linear(self.attn_in, attn_dim)

    def forward(self,
                decoder_hidden: Tensor,
                encoder_outputs: Tensor) -> Tensor:

        src_len = encoder_outputs.shape[0]

        repeated_decoder_hidden = decoder_hidden.unsqueeze(1).repeat(1, src_len, 1)

        encoder_outputs = encoder_outputs.permute(1, 0, 2)

        energy = torch.tanh(self.attn(torch.cat((
            repeated_decoder_hidden,
            encoder_outputs),
            dim=2)))

        attention = torch.sum(energy, dim=2)

        return F.softmax(attention, dim=1)


class Decoder(nn.Module):
    def __init__(self,
                 output_dim: int,
                 emb_dim: int,
                 enc_hid_dim: int,
                 dec_hid_dim: int,
                 dropout: int,
                 attention: nn.Module):
        super().__init__()

        self.emb_dim = emb_dim
        self.enc_hid_dim = enc_hid_dim
        self.dec_hid_dim = dec_hid_dim
        self.output_dim = output_dim
        self.dropout = dropout
        self.attention = attention

        self.embedding = nn.Embedding(output_dim, emb_dim)

        self.rnn = nn.GRU((enc_hid_dim * 2) + emb_dim, dec_hid_dim)

        self.out = nn.Linear(self.attention.attn_in + emb_dim, output_dim)

        self.dropout = nn.Dropout(dropout)

    def _weighted_encoder_rep(self,
                              decoder_hidden: Tensor,
                              encoder_outputs: Tensor) -> Tensor:

        a = self.attention(decoder_hidden, encoder_outputs)

        a = a.unsqueeze(1)

        encoder_outputs = encoder_outputs.permute(1, 0, 2)

        weighted_encoder_rep = torch.bmm(a, encoder_outputs)

        weighted_encoder_rep = weighted_encoder_rep.permute(1, 0, 2)

        return weighted_encoder_rep

    def forward(self,
                input_: Tensor,
                decoder_hidden: Tensor,
                encoder_outputs: Tensor) -> Tuple[Tensor]:

        input_ = input_.unsqueeze(0)

        embedded = self.dropout(self.embedding(input_))

        weighted_encoder_rep = self._weighted_encoder_rep(decoder_hidden,
                                                          encoder_outputs)

        rnn_input = torch.cat((embedded, weighted_encoder_rep), dim=2)

        output, decoder_hidden = self.rnn(rnn_input, decoder_hidden.unsqueeze(0))

        embedded = embedded.squeeze(0)
        output = output.squeeze(0)
        weighted_encoder_rep = weighted_encoder_rep.squeeze(0)

        output = self.out(torch.cat((output,
                                     weighted_encoder_rep,
                                     embedded), dim=1))

        return output, decoder_hidden.squeeze(0)


class Seq2Seq(nn.Module):
    def __init__(self,
                 encoder: nn.Module,
                 decoder: nn.Module):
        super().__init__()

        self.encoder = encoder
        self.decoder = decoder

    def forward(self,
                src: Tensor,
                trg: Tensor,
                teacher_forcing_ratio: float = 0.5) -> Tensor:

        batch_size = src.shape[1]
        max_len = trg.shape[0]
        trg_vocab_size = self.decoder.output_dim

        encoder_outputs, hidden = self.encoder(src)

        # first input to the decoder is the <sos> token
        output = trg[0, :]
        outputs = torch.zeros(max_len, batch_size, trg_vocab_size).type_as(encoder_outputs)

        for t in range(1, max_len):
            output, hidden = self.decoder(output, hidden, encoder_outputs)
            outputs[t] = output
            teacher_force = random.random() < teacher_forcing_ratio
            top1 = output.max(1)[1]
            output = (trg[t] if teacher_force else top1)

        return outputs


class AttnAE(LightningModule):
    def __init__(
            self,
            input_dim,
            output_dim,
            embedding_dim,
            hidden_dim,
            attention_dim,
            dropout,
            pad_idx,
            vocab
    ):
        super().__init__()
        self.save_hyperparameters('input_dim', 'output_dim', 'embedding_dim', 'hidden_dim', 'attention_dim', 'dropout')
        self.encoder = Encoder(input_dim, embedding_dim, hidden_dim, hidden_dim, dropout)
        self.attn = Attention(hidden_dim, hidden_dim, attention_dim)
        self.decoder = Decoder(output_dim, embedding_dim, hidden_dim, hidden_dim, dropout, self.attn)
        self.model = Seq2Seq(self.encoder, self.decoder)
        self.vocab = vocab
        self.pad_idx = pad_idx

        # Init weights
        for name, param in self.model.named_parameters():
            if 'weight' in name:
                nn.init.normal_(param.data, mean=0, std=0.01)
            else:
                nn.init.constant_(param.data, 0)

        self.loss = nn.CrossEntropyLoss(ignore_index=pad_idx)
        self.accuracy = torchmetrics.Accuracy(ignore_index=pad_idx)

    def training_step(self, batch, batch_idx):
        input_, target = batch

        tf = 1 * max(((200 - self.current_epoch) / 200), 0.05)
        self.model.train(True)
        output = self.model(input_, target, tf)

        output = output[1:].view(-1, output.shape[-1])
        target = target[1:].view(-1)

        loss = self.loss(output, target)

        self.log('loss', loss)
        self.log('teacher-force', tf, prog_bar=True)

        return loss

    def validation_step(self, batch, batch_idx):
        input_, target = batch

        self.model.eval()
        output = self.model(input_, target, 0)
        ot = output[1:].view(-1, output.shape[-1])
        tg = target[1:].view(-1)

        val_loss = self.loss(ot, tg)

        output = output.permute(1, 0, 2)
        target = target.permute(1, 0)
        predicted_words = output.argmax(dim=2)

        accs = []
        for idx, (gold, pred) in enumerate(zip(target, predicted_words)):
            gold_sentence = [self.vocab.itos[i] for i in gold[1:] if i != self.pad_idx]
            predicted_sentence = [self.vocab.itos[i] for id_, i in enumerate(pred[1:]) if id_ < len(gold_sentence)]
            #if idx == 0:
            print(f'\n> {" ".join(gold_sentence)}\n< {" ".join(predicted_sentence)}\n')
            accs.append(self.accuracy(gold[1:len(gold_sentence)], pred[1:len(predicted_sentence)]))

        acc = torch.mean(torch.tensor(accs))

        self.log('val_acc', acc, prog_bar=True)
        self.log('val_loss', val_loss, prog_bar=True)

        return acc

    def configure_optimizers(self):
        return torch.optim.Adam(self.model.parameters(), lr=0.001)
