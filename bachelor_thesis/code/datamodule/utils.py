import pandas as pd
import numpy as np
import re
import torch
import nltk
from nltk.corpus import stopwords
from scipy.sparse import coo_matrix
from tqdm import tqdm
import swifter


class Lemmatize(object):
    def __init__(self):
        self.tokenizer = nltk.tokenize.WhitespaceTokenizer()
        self.lemmatizer = nltk.stem.WordNetLemmatizer()

    def __call__(self, df: pd.DataFrame):
        print('Lemmatizing text...')
        def lemmatize_text(sentence):
            return [self.lemmatizer.lemmatize(word) for word in self.tokenizer.tokenize(sentence)]
        return df.swifter.apply(lemmatize_text)


class RemoveAccents(object):
    def __call__(self, df: pd.DataFrame):
        print('Removing accents...')
        def normalizeString(s):
            s = s.lower().strip()
            s = re.sub(r"([.!?])", r" \1", s)
            s = re.sub(r"[^a-zA-Z.!?]+", r" ", s)
            return s

        df = df[~df.str.contains('ě|š|č|ř|ž|ý|á|í|é|ů|ú|ň|ď|ť')]
        df = df.apply(normalizeString)
        return df


class RemoveStopwords(object):
    def __init__(self):
        self.stop_words = stopwords.words('english')
        self.stop_words.extend(['aim', 'goal', 'project', 'evaluate', 'research', 'improve', 'improvement', 'development'])

    def __call__(self, df: pd.DataFrame):
        print('Removing stopwords...')
        def remove_stopwords(sentence):
            new_sentence = []
            for word in sentence:
                if word not in self.stop_words:
                    new_sentence.append(word)

            if isinstance(sentence, list):
                return new_sentence
            elif isinstance(sentence, str):
                return ' '.join(new_sentence)
            else:
                raise NotImplementedError('Invalid type of row format.')
        return df.apply(remove_stopwords)


class TrimSentences(object):
    def __init__(self, max_len):
        self.max_len = max_len

    def __call__(self, df: pd.DataFrame):
        print('Trimming sentences...')
        return df.apply(lambda x: x[:self.max_len - 1])


class PadSentences(object):
    def __init__(self, pad_with):
        self.pad_with = pad_with

    def __call__(self, df: pd.DataFrame):
        print('Padding sentences...')
        new_df = pd.DataFrame()
        longest_sentence = df.map(lambda x: len(x)).max()

        new_df['input'] = df.apply(lambda x: ['<sos>'] + x)
        new_df['target'] = df.apply(lambda x: x + ['<eos>'])
        new_df['length'] = new_df['input'].apply(lambda x: len(x))

        def pad_sentence(sentence, max_len=None, pad_with=None):
            sentence.extend([pad_with] * (max_len + 1 - len(sentence)))
            return sentence
        new_df['input'] = new_df['input'].apply(pad_sentence, max_len=longest_sentence, pad_with=self.pad_with)
        new_df['target'] = new_df['target'].apply(pad_sentence, max_len=longest_sentence, pad_with=self.pad_with)
        new_df.sort_values('length', ascending=False, inplace=True)
        return new_df


class ConvertToBagOfWords(object):
    def __call__(self, df: pd.DataFrame, w2i):
        def convert_to_cbow(sentence):
            sentence_encoding = np.zeros((len(sentence), len(w2i)), dtype=np.uint8)
            for index, word in enumerate(sentence):
                sentence_encoding[index][w2i[word]] = 1
            matrix = coo_matrix(sentence_encoding)
            return matrix

        print('Converting to CBOW...')
        df['input'] = df['input'].swifter.apply(convert_to_cbow)
        df['target'] = df['target'].swifter.apply(convert_to_cbow)
        df['length'] = df['length'].astype(np.int16)
        return df.to_numpy()


def replace_nan_drop_empty(df: pd.DataFrame, replacement: str):
    df = df.dropna(how='any')
    df = df.fillna(value=replacement)
    df = df[~(df.apply(''.join, axis=1).str.len() < 10)]
    return df


