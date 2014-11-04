import sys, os
from process_sat import input_cnstr, connected, dot, output_dimacs, write_game_files

NODE_LIMIT = 100

### Command line interface ###
if __name__ == "__main__":
    usage = 'Usage: %s constraint_filename_prefix_omit_json_extension' % sys.argv[0]
    if len(sys.argv) != 2:
        print usage
        quit()
    file_pref = sys.argv[1]

    constr_fn = '%s.json' % file_pref
    graph_fn = '%s.graph' % file_pref
    version = input_cnstr.run(constr_fn, graph_fn)

    graphs_fn = '%s.graphs' % file_pref
    connected.run(graph_fn, graphs_fn)

    dot_dirn = '%s_dot_files' % file_pref
    suf_i = 0
    while os.path.exists(dot_dirn):
        suf_i += 1
        dot_dirn = '%s_dot_files_%s' % (file_pref, suf_i)
    os.makedirs(dot_dirn)
    print 'Writing dot files to: %s' % dot_dirn
    dot.run(graphs_fn, dot_dirn, NODE_LIMIT)

    # wcnf_dirn = '%s_wcnf_files' % file_pref
    # suf_i = 0
    # while os.path.exists(wcnf_dirn):
    #     suf_i += 1
    #     wcnf_dirn = '%s_wcnf_files_%s' % (file_pref, suf_i)
    # os.makedirs(wcnf_dirn)
    # print 'Writing wcnf files to: %s' % wcnf_dirn
    # output_dimacs.run(graphs_fn, wcnf_dirn)

    game_files_dirn = '%s_game_files' % file_pref
    suf_i = 0
    while os.path.exists(game_files_dirn):
        suf_i += 1
        game_files_dirn = '%s_game_files%s' % (file_pref, suf_i)
    os.makedirs(game_files_dirn)
    print 'Writing game files to: %s' % game_files_dirn
    qids_start = 2000
    write_game_files.run(graphs_fn, game_files_dirn, version, qids_start, NODE_LIMIT)

