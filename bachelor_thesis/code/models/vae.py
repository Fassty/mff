from pytorch_lightning import LightningModule
import torch
import torch.nn.utils.rnn as rnn_utils
from torch import nn


class Encoder(nn.Module):
    def __init__(
            self,
            input_dim,
            hidden_dim,
            latent_dim,
            cell_type,
            n_layers,
            bidirectional
    ):
        super().__init__()
        self.bidirectional = bidirectional
        self.n_layers = n_layers
        self.hidden_dim = hidden_dim
        self.latent_dim = latent_dim
        self.hidden_factor = (bidirectional + 1) * n_layers
        self.cell_type = cell_type

        self.rnn = getattr(nn, cell_type.upper())(
            input_dim, hidden_dim, num_layers=n_layers, bidirectional=bidirectional, batch_first=True
        )

        self.mu = nn.Linear(in_features=hidden_dim * self.hidden_factor, out_features=latent_dim)
        self.log_var = nn.Linear(in_features=hidden_dim * self.hidden_factor, out_features=latent_dim)

    def forward(self, input_, lengths):
        # sort input sequences by length
        batch_size = input_.size(0)
        sorted_lengths, sorted_idx = torch.sort(lengths, descending=True)
        input_ = input_[sorted_idx]

        # remove padding -> trim sequences by corresponding length
        packed_input = rnn_utils.pack_padded_sequence(input_, sorted_lengths.data.tolist(), batch_first=True)

        # get the last hidden state of the encoder RNN
        _, hidden = self.rnn(packed_input)

        # process LSTM output
        if self.cell_type == 'lstm':
            # return last hidden state of last layer
            hidden_state, cell_state = hidden
            hidden_state = hidden_state.view(self.n_layers, (self.bidirectional + 1), batch_size, self.hidden_dim)
            hidden_state = hidden_state[-1]
            # concat forward and backward output for bidirectional RNN
            hidden_states = [hidden_state[i] for i in range(self.bidirectional + 1)]
            hidden_state = torch.cat(hidden_states, dim=1)
        else:
            hidden_state = hidden

        # reparametrize
        mu = self.mu(hidden_state)
        log_var = self.log_var(hidden_state)
        std = torch.exp(0.5 * log_var)
        z = torch.rand([batch_size, self.latent_dim]).type_as(mu)
        z = z * std + mu
        return z, mu, std, sorted_idx, hidden


class Decoder(nn.Module):
    def __init__(
            self,
            input_dim,
            hidden_dim,
            latent_dim,
            cell_type,
            n_layers,
            bidirectional,
            seq_len
    ):
        super().__init__()
        self.input_dim = input_dim
        self.hidden_dim = hidden_dim
        self.seq_len = seq_len
        self.hidden_factor = (bidirectional + 1) * n_layers

        self.rnn = getattr(nn, cell_type.upper())(
            latent_dim, hidden_dim, num_layers=n_layers, bidirectional=bidirectional, batch_first=True
        )
        self.fc = nn.Linear(hidden_dim * self.hidden_factor, input_dim)
        self.softmax = nn.LogSoftmax(dim=-1)

    def forward(self, z, sorted_idx, hidden):
        # repeat encoded latent variable for each word in input sequence
        input_ = z.unsqueeze(1).repeat(1, self.seq_len, 1)

        # decode sampled latent variable
        output, hidden = self.rnn(input_)

        # order data in memory
        output = output.contiguous()

        # reorder data back to their original ordering
        _, reversed_idx = torch.sort(sorted_idx)
        output = output[reversed_idx]

        # flatten RNN output
        batch_size, seq_len, hidden_size = output.size()
        output = output.view(-1, hidden_size)

        # project outputs back to vocabulary -> calculate probabilities
        fc_output = self.fc(output)
        log_prob = self.softmax(fc_output)

        # reshape to match the dimensions of input
        log_prob = log_prob.view(batch_size, seq_len, -1)
        return log_prob


class VAE(LightningModule):
    def __init__(
            self,
            input_dim,
            hidden_dim,
            latent_dim,
            seq_len,
            cell_type,
            n_layers,
            bidirectional,
            index2word,
            word2index
    ):
        super().__init__()
        self.encoder = Encoder(input_dim, hidden_dim, latent_dim, cell_type, n_layers, bidirectional)
        self.decoder = Decoder(input_dim, hidden_dim, latent_dim, cell_type, n_layers, bidirectional, seq_len)
        self.index2word = index2word
        self.word2index = word2index
        self.reconstruction_loss = nn.NLLLoss(ignore_index=word2index['<pad>'], reduction='sum')

    def kl_divergence(self, mean, std):
        """Simplified KL divergence calculation expecting the posterior to be N(0, 1)"""
        return -0.5 * torch.sum(1 + torch.log(std) - mean.pow(2) - std)

    def training_step(self, batch, batch_idx):
        input_, target, length = batch

        z, mu, std, sorted_idx, hidden = self.encoder(input_, length)
        log_prob = self.decoder(z, sorted_idx, hidden)

        vocab_size = log_prob.size(2)

        # convert one-hot encoding to vocabulary indices
        target = target.argmax(dim=2).view(-1)
        log_prob = log_prob.view(-1, vocab_size)

        # kl divergence weighted by the sequence length
        kl = self.kl_divergence(mu, std) * z.size(1)
        rloss = self.reconstruction_loss(log_prob, target)

        loss = kl + rloss
        self.log('train_loss', loss)
        return loss

    def validation_step(self, batch, batch_idx):
        input_, target, length = batch

        z, mu, std, sorted_idx, hidden = self.encoder(input_, length)
        log_prob = self.decoder(z, sorted_idx, hidden)

        vocab_size = log_prob.size(2)
        target = target.argmax(dim=2).view(-1)
        log_prob = log_prob.view(-1, vocab_size)

        kl = self.kl_divergence(mu, std) * z.size(1)
        rloss = self.reconstruction_loss(log_prob, target)

        loss = kl + rloss

        self.log('val_loss', loss)
        return loss

        # index_max = torch.argmax(reconstruction, dim=2)
        # gold_index_max = torch.argmax(batch[1], dim=2)
        # accuracy = 0
        # for predicted_sentence_idxs, gold_sentence_idxs in zip(index_max, gold_index_max):
        #     predicted_sentence = [self.index2word[word_index.item()] for word_index in predicted_sentence_idxs]
        #     gold_sentence = [self.index2word[word_index.item()] for word_index in gold_sentence_idxs]
        #     correct = sum([1 if x == y else 0 for x, y in zip(predicted_sentence, gold_sentence)])
        #     accuracy = correct / len(predicted_sentence)
        #
        # self.log('val_accuracy', accuracy)
        # return accuracy

    def configure_optimizers(self):
        return torch.optim.Adam(self.parameters(), lr=0.001)
