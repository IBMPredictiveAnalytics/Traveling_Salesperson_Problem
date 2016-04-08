# STATS_TSP

Solves the traveling salesperson optimization problem

STATS TSP NODES = node variables*
/OPTIONS START = starting node variable
TYPE = TSP** or ATSP
METHOD = FARTHEST** or NEAREST or CHEAPEST or ARBITRARY or NN or REPETITIVE or TWO_OPT
* Required
** Default

STATS TSP /HELP prints this information and does nothing else.

STATS TSP NODES=city1 city2 city3 city4 city5 city6
/OPTIONS START=city3.
This extension uses the TSP package in R to solve the traveling salesperson optimization problem. The extension supports both symmetric and asymmetric costs (distances).

In what follows, the term node is used to represent the points or locations to be included in the optimization problem and the term cost describes the distance or generalized distance between nodes.

The active dataset must contain one variable for each node to be included. The value of the ith case for a particular variable is the cost from the node represented by the variable to the node represented by the ith variable in file order. The value of the ith case for the ith variable in file order must be 0. The following table shows an example of the data structure for four nodes that are represented by the variables Node1, Node2, Node3 and Node4. For example, the cost between Node1 and Node2 is 1167.

Node1	Node2	Node3	Node4
0	1167	1579	437
1167	0	413	1422
1579	413	0	1832
437	1422	1832	0
NODES specifies the names of the variables that represent the nodes to be included in the optimization problem. You can set the starting node with the START keyword on OPTIONS.

OPTIONS

START specifies the name of the variable that represents the starting node, if any.

TYPE specifies whether costs are symmetric or asymmetric. Symmetric or asymmetric refers to whether the cost from node i to node j is the same as the cost from node j to node i. When the costs are the same for all i and j, the costs are symmetric. TSP specifies symmetric and ATSP specifies asymmetric. The default is TSP.

METHOD specifies the heuristics method.

FARTHEST. Farthest insertion method. In each step of the insertion process, the inserted node is the one which is farthest from any of the previously inserted nodes.
NEAREST. Nearest insertion method. In each step of the insertion process, the inserted node is the one which is nearest to one of the previously inserted nodes.
CHEAPEST. Cheapest insertion method. In each step of the insertion process, the inserted node is the one which has the smallest insertion cost.
ARBITRARY. Arbitrary insertion method. In each step of the insertion process, the inserted node is randomly selected from the nodes that have not yet been inserted.
NN. Nearest neighbor method. In each step, add the node that is closest to the last added node. The first node is randomly selected.
REPETITIVE. Repetitive nearest neighbor method. Repeats the nearest neighbor method using each node as the starting point and then selects the best solution from that set.
TWO_OPT. 2-Opt method.
Acknowledgements

This extension uses the R TSP package written by Michael Hahsler and Kurt Hornik.
