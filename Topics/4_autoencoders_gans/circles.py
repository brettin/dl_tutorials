import numpy as np

from sklearn.datasets import make_circles

noise = 0.2
factor = 0.5

x_train, y_train = make_circles(n_samples=10, noise=noise, factor=factor)
x_test, y_test = make_circles(n_samples=100, noise=noise, factor=factor)
x, _ = make_circles(n_samples=100000, noise=noise, factor=factor)

from sklearn.ensemble import RandomForestClassifier, AdaBoostClassifier
from sklearn.model_selection import cross_val_score
from sklearn.svm import SVC


import keras
from keras.layers import Input, Dense
from keras.models import Model

activation = 'tanh'
input_vector = Input(shape=(2,))
h = Dense(20, activation=activation)(input_vector)
h = Dense(10, activation=activation)(h)
h = Dense(4, activation=activation)(h)
encoded = h

h = Dense(10, activation=activation)(h)
h = Dense(20, activation=activation)(h)
h = Dense(2, activation=activation)(h)

ae = Model(input_vector, h)
ae.summary()

encoded_input = Input(shape=(4,))
decoder = Model(encoded_input, ae.layers[-1](ae.layers[-2](ae.layers[-3](encoded_input))))
encoder = Model(input_vector, encoded)

ae.compile(optimizer='rmsprop', loss='mse')

ae.fit(x, x, batch_size=100, epochs=2, validation_split=0.1)

x_train_latent = encoder.predict(x_train)
x_test_latent = encoder.predict(x_test)

c1 = RandomForestClassifier()
c1.fit(x_train, y_train)
s1 = c1.score(x_test, y_test)
print('Supervised learning:      ', s1)

c2 = RandomForestClassifier()
c2.fit(x_train_latent, y_train)
s2 = c2.score(x_test_latent, y_test)
print('Semi-supervised learning: ', s2)

c3 = RandomForestClassifier()
c3.fit(np.hstack((x_train, x_train_latent)), y_train)
s3 = c3.score(np.hstack((x_test, x_test_latent)), y_test)
print('Combined learning:        ', s3)
