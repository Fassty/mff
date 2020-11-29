import re

# Load input dimensions
n_nodes, n_edges = map(int, re.findall(r'\d+', input()))

# Load all edges with their weights as three tuples
weighted_edges = []
nodes = list(range(n_nodes))
for i in range(n_edges):
    edge = tuple(map(int, re.findall(r'\d+', input())))
    weighted_edges.append(edge)

# Retrieve edges without weights for searching
edges = [(i, j) for i,j,_ in weighted_edges]

# Search at depth 3 and 4 for any cycles of that length
cycles = []
for n1 in nodes:
    for n2 in [n for n in nodes if (n1, n) in edges]:
        for n3 in [n for n in nodes if (n2, n) in edges]:
            for n4 in [n for n in nodes if (n3, n) in edges]:
                if n1 == n4:
                    cycle = set([(n1, n2), (n2, n3), (n3, n4)])
                    if cycle not in cycles:
                        cycles.append(cycle)
                for n5 in [n for n in nodes if (n4, n) in edges]:
                    if n1 == n5:
                        cycle = set([(n1, n2), (n2, n3), (n3, n4), (n4, n5)])
                        if cycle not in cycles:
                            cycles.append(cycle)

# Build the program as a string
program_string = []
program_string.append(f"param N := {str(n_nodes)};")

# Represent edges as a set of comma separated pairs
edge_string = ', '.join(f"({i+1}, {j+1})" for i, j in edges)
program_string.append(f"set edges := {{{edge_string}}};")

# Predefine weights to have dimension of NxN
program_string.append("param e{i in 1..N, j in 1..N};")

# Define binary variables for edges
program_string.append("var x{i in 1..N, j in 1..N}, >=0, <=1, integer;")

# Minimize the weighted sum of edges
program_string.append("minimize obj: sum{(i, j) in edges} (e[i, j] * x[i, j]);")

# Define constraints that atleast one edge of the cycle must be included in the result
cycles_string = []
for cycle in cycles:
    cycles_string.append(" + ".join(f"x[{i+1}, {j+1}]" for i, j in cycle))
program_string.append('\n'.join([f"c{i+1}: {cycle} >= 1;" for i, cycle in enumerate(cycles_string)]))
program_string.append("solve;")

# Add output summary
program_string.append('printf "#OUTPUT: %d\\n", obj;')
program_string.append("for {(i, j) in edges : x[i, j] >= 1} {")
program_string.append('    printf "%d --> %d\\n", i-1, j-1;\n}')
program_string.append('printf "#OUTPUT END\\n";')
program_string.append("data;")

# Provide weighted edges as input to the program
weights_string = ' '.join([f"[{i+1}, {j+1}] {w}" for i, j, w in weighted_edges])
program_string.append(f"param e := {weights_string};")
program_string.append("end;")

print('\n'.join(program_string))
