import csv
import numpy
from matplotlib import pyplot as plt 

def average(v):
    s = 0.0

    for i in v:
        s += i

    return s / len(v)


flag = 129100
c = 0
values = []
with open('database.csv') as csvfile:
    reader = csv.DictReader(csvfile)

    for row in reader:
        c += 1

        if c > flag:
            values.append(int(row['H']) - int(row['L']))

print('Average = {}'.format(average(values)))
print('STDEV = {}'.format(numpy.std(values)))
print('Max = {}, Min = {}'.format(numpy.amax(values), numpy.amin(values)))
#print('Histogram = {}'.format(numpy.histogram(values, 20)))

bins = numpy.arange(0, 1000, 15)

plt.hist(values, bins=bins)
plt.title("histogram") 
plt.show()
