import networkx as nx
from networkx.algorithms.approximation import clique
from networkx.algorithms import bipartite
import json
import xlsxwriter as xls

with open("gameplay.json") as data_file:
    data = json.load(data_file)

ratings = {
	"gen_tree_lb": 2275.71799,
	"gen_rsets_m2a": 2218.85825,
	"s3v70c800-3": 2197.131767,
	"gen_rsets_l2a": 2188.411947,
	"par8-1-c": 2152.19852,
	"par8-4-c": 2136.586152,
	"gen_tree_la": 2086.59887,
	"par8-3-c": 2080.044216,
	"par8-2-c": 2053.985802,
	"aim-50-1_6-yes1-4": 2019.908853,
	"gen_rsets_s2a": 1880.143997,
	"uuf50-01": 1813.020084,
	"uf50-050": 1808.671458,
	"uuf75-01": 1770.977513,
	"anomaly": 1739.092374,
	"uf20-01": 1723.199433,
	"uuf50-050": 1648.521893,
	"flat75-1": 1625.383292,
	"medium": 1616.283128,
	"BMS_k3_n100_m429_340": 1586.851991,
	"flat50-1": 1523.906471,
	"pret150_25": 1517.01276,
	"pret150_75": 1508.957096,
	"gen_rsets_l1a": 1488.581219,
	"pret60_25": 1476.086314,
	"uf50-01": 1469.011955,
	"gen_tree_sb": 1419.189503,
	"dubois25": 1413.242352,
	"flat50-50": 1366.549876,
	"pret60_75": 1328.417768,
	"gen_tree_mb": 1325.358775,
	"dubois21": 1317.512891,
	"gen_rsets_m1a": 1310.633389,
	"dubois27": 1222.146777,
	"hole10": 1209.528395,
	"gen_tree_ma": 1198.456412,
	"dubois20": 1141.183426,
	"quinn": 1121.401589,
	"dubois50": 1104.826323,
	"ii8a2": 1095.472624,
	"hole6": 1069.126132,
	"ii8a1": 1068.088063,
	"gen_rsets_s1a": 1062.315809,
	"hole8": 1052.098769,
	"hole7": 1040.737466,
	"flat30-10": 1013.481321,
	"ais6": 1007.252684,
	"hole9": 966.4523866,
	"gen_tree_sa": 960.7094616,
	"flat30-100": 892.2170777
}

filename = "LevelFeatures.xlsx"
databook = xls.Workbook(filename)
datasheet = databook.add_worksheet("Level_Features")
datasheet.write('A1','Name')
datasheet.write('B1','% edges in MST')
datasheet.write('C1','Clique Number')
datasheet.write('D1','Assortativity Coefficient')
datasheet.write('E1','Estrada Index')
datasheet.write('F1','# Maximal Cliques')
datasheet.write('G1','Diameter')
datasheet.write('H1','Radius')
datasheet.write('I1','Center Size')
datasheet.write('J1','Periphery Size')
datasheet.write('K1','Max Matching Size')
datasheet.write('L1','Max Independent Set')
datasheet.write('M1','Avg Shortest Path')
datasheet.write('N1','Density')
datasheet.write('O1','Rating')

levels = data["levels"]
count = 2
for level in levels:
    constraints = level["constraints"]
    name = level["file"]
    print name, ': '
    G = nx.Graph()
    for cnstr in constraints:
        idx = cnstr.index("<=")
        G.add_edge(cnstr[:idx-1], cnstr[idx+3:])
    MST = nx.minimum_spanning_edges(G)
    #max_clique = clique.max_clique(G)
    gqn = nx.graph_clique_number(G)
    num_edges, num_nodes, num_mst_edges = G.number_of_edges(), G.number_of_nodes(), len(list(MST))
    assortativity = nx.degree_assortativity_coefficient(G)
    pearson_assortativity = nx.degree_pearson_correlation_coefficient(G)
    avg_deg_con = nx.average_degree_connectivity(G)
    #eigen_cen = nx.eigenvector_centrality(G)
    #deg_cen = nx.degree_centrality(G)
    ave_clust = nx.average_clustering(G)
    estrada = nx.estrada_index(G)
    transitivity = nx.transitivity(G)
    #avg_node_con = nx.average_node_connectivity(G)
    num_cliques = nx.graph_number_of_cliques(G)
    center = nx.center(G)
    diameter = nx.diameter(G)
    periphery = nx.periphery(G)
    radius = nx.radius(G)
    max_match = nx.maximal_matching(G)
    maximal_ind_set = nx.maximal_independent_set(G)
    avg_shortest_path = nx.average_shortest_path_length(G)
    density = nx.density(G)
    #rich_club = nx.rich_club_coefficient(G)
    datasheet.write('A' + str(count), name)
    print "#Edges: ", num_edges
    print "#Nodes: ", num_nodes
    print "#Edges in MST: ", num_mst_edges
    print "%Edges in MST: ", (num_mst_edges*100.0)/num_edges
    datasheet.write('B' + str(count), (num_mst_edges*100.0)/num_edges)
    #print "Connected?: ", nx.is_connected(G)
    #print "#Connected Components: ", nx.number_connected_components(G)
    #print "#Biconnected?: ", nx.is_biconnected(G)
    #print "Max Clique: ", max_clique
    print "GQN: ", gqn
    datasheet.write('C' + str(count), gqn)
    #print ("%s %.2f") % ("Average Clustering: ", ave_clust)
    print "Degree Assortativity Coefficient: ", assortativity
    #print "Pearson Degree Assortativity Coefficient: ", pearson_assortativity
    #print "Average Degree Connectivity: ", avg_deg_con
    #print "Bipartite?: ", bipartite.is_bipartite(G)
    datasheet.write('D' + str(count), assortativity)
    print "Estrada: ", estrada
    datasheet.write('E' + str(count), estrada)
    print "# Cliques: ", num_cliques
    datasheet.write('F' + str(count), num_cliques)
    print "Diameter: ", diameter
    datasheet.write('G' + str(count), diameter)
    print "Radius: ", radius
    datasheet.write('H' + str(count), radius)
    #print "Average Node Connectivity: ", avg_node_con
    print "Center Size: ", len(center)
    datasheet.write('I' + str(count), len(center))
    print "Periphery Size: ", len(periphery)
    datasheet.write('J' + str(count), len(periphery))
    print "Maximal Matching Size: ", len(max_match)
    datasheet.write('K' + str(count), len(max_match))
    print "Max Ind Set Size: ", len(maximal_ind_set)
    datasheet.write('L' + str(count), len(maximal_ind_set))
    #print "Rich Club Coeff: ", rich_club
    print "Avg Shortest Path Length: ", avg_shortest_path
    datasheet.write('M' + str(count), avg_shortest_path)
    print "Density: ", density
    datasheet.write('N' + str(count), density)
    print "Rating: ", ratings[name]
    datasheet.write('O' + str(count), ratings[name])
    count += 1
    print
    
databook.close()
