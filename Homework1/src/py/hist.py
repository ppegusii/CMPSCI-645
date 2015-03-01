from __future__ import print_function
from sys import argv
from csv import reader
import matplotlib.pyplot as plt

def main():
    print(argv)
    with open(argv[1],'rU') as csv:
        csvReader = reader(csv)
        k = list()
        fk = list()
        for row in csvReader:
            k.append(row[0])
            fk.append(row[1])
        plt.scatter(k,fk)
        plt.xlabel('k')
        plt.ylabel('f(k)')
        if argv[2] == 'loglog':
            plt.loglog()
        plt.show()

if __name__=='__main__':
    main()
