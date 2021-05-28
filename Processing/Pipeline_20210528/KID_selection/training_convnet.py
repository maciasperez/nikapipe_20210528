# USAGE
# python training_convnet.py --save-model 1 --weights output/lenet_weights.hdf5
# python training_convnet.py --load-model 1 --weights output/lenet_weights.hdf5

# import the necessary packages
from pyimagesearch.cnn.networks import LeNet
from sklearn.cross_validation import train_test_split
from sklearn import datasets
from keras.optimizers import SGD
from keras.utils import np_utils
import numpy as np
from astropy.io import fits
import argparse
import cv2
import pdb
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
import os

# construct the argument parse and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("-s", "--save-model", type=int, default=-1,
	help="(optional) whether or not model should be saved to disk")
ap.add_argument("-l", "--load-model", type=int, default=-1,
	help="(optional) whether or not pre-trained model should be loaded")
ap.add_argument("-w", "--weights", type=str,
	help="(optional) path to weights file")
args = vars(ap.parse_args())

#===============
#Training files:
#===============
hdu = fits.open('/Users/ruppin/Projects/NIKA/Soft/branch/Florian/FR/These/Neural_network/Data_beammap/image_dataset_training.fits')
data = hdu[0].data
data = np.transpose(data)
hdu2 = fits.open('/Users/ruppin/Projects/NIKA/Soft/branch/Florian/FR/These/Neural_network/Data_beammap/class_dataset_training.fits')
targets = hdu2[0].data
data = data[:, np.newaxis, :, :]
(trainData, testData, trainLabels, testLabels) = train_test_split(data, targets.astype("int"), test_size=0.3)

#=================================================================
# Transform the training and testing labels into vectors in the
# range [0, classes] -- this generates a vector for each label,
# where the index of the label is set to `1` and all other entries
# to `0`; 
#=================================================================
trainLabels = np_utils.to_categorical(trainLabels, num_classes=2)
testLabels = np_utils.to_categorical(testLabels, num_classes=2)

#===================================
# Initialize the optimizer and model
#===================================
print("[INFO] compiling model...")
opt = SGD(lr=0.01)
model = LeNet.build(width=221, height=221, depth=1, classes=2,
	            weightsPath=args["weights"] if args["load_model"] > 0 else None)
model.compile(loss="categorical_crossentropy", optimizer=opt,
	      metrics=["accuracy"])

#============================================================
# only train and evaluate the model if we *are not* loading a
# pre-existing model
#============================================================
if args["load_model"] < 0:
	print("[INFO] training...")
	model.fit(trainData, trainLabels, batch_size=128, epochs=250,
		verbose=1)

	# show the accuracy on the testing set
	print("[INFO] evaluating...")
	(loss, accuracy) = model.evaluate(testData, testLabels,
		batch_size=128, verbose=1)
	print("[INFO] accuracy: {:.2f}%".format(accuracy * 100))

#==================================================
# check to see if the model should be saved to file
#==================================================
if args["save_model"] > 0:
	print("[INFO] dumping weights to file...")
	model.save_weights(args["weights"], overwrite=True)

cmap = ListedColormap(np.loadtxt(os.environ["SZ_PIPE"]+"/Colormaps/nika_cmap.txt")/255.)
# randomly select a few testing digits
for i in np.random.choice(np.arange(0, len(testLabels)), size=(100,)):
	# classify the digit
	probs = model.predict(testData[np.newaxis, i])
	prediction = probs.argmax(axis=1)
    
	# show the image and prediction
	print("[INFO] Predicted: {}, Actual: {}".format(prediction[0],
		np.argmax(testLabels[i])))

        plt.imshow(np.transpose(testData[i][0]),cmap=cmap)
        plt.title("Type: "+str(prediction[0]))
        plt.show()
