# Tidy Trees
Trees (e.g. from packages like "partykit" or "rpart") are a very powerful set of statistical learning algorithms.
		Nevertheless each tree package has its own way of representing and storing the trees, usually as a nested recursive list with attributes. This makes it very hard to get a glance at the tree's characteristics, expecially its rules.
		This package provides an interface to convert tree objects from various packages into a data frame like structure, with the set of rules defining each node and its characteristics.
