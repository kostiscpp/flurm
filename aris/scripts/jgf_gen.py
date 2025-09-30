#!/usr/bin/env python3
import argparse, json
from typing import List, Dict

def add_node(nodes: List[Dict], *, id_str: str, meta: Dict):
    nodes.append({
        "id": id_str,
        "metadata": meta,
    })

def add_edge(edges: List[Dict], *, src: str, dst: str, subsystem="containment"):
    edges.append({
        "source": src,
        "target": dst,
        "metadata": {"subsystem": subsystem},
    })

def gen_graph(cluster_name: str, hosts: List[str], sockets: int, cores: int, start_uid: int = 0):
    """
    Build a graph object like your example:
      { "graph": { "nodes": [...], "edges": [...] } }
    with the containment path: /cluster/<node>/socketX/coreY
    """
    nodes, edges = [], []
    uniq = start_uid

    # 1) Cluster node
    cluster_id = str(uniq); uniq += 1
    add_node(nodes,
        id_str=cluster_id,
        meta={
            "type": "cluster",
            "basename": "cluster",
            "name": cluster_name,
            "id": 0,
            "uniq_id": int(cluster_id),
            "rank": -1,
            "exclusive": False,
            "unit": "",
            "size": 1,
            "paths": { "containment": f"/{cluster_name}" },
        },
    )

    # 2) For each host: node -> socket[i] -> core[j]
    for r, host in enumerate(hosts):
        node_id = str(uniq); uniq += 1
        add_node(nodes,
            id_str=node_id,
            meta={
                "type": "node",
                "basename": host,
                "name": host,
                # Your example put -1 here; we’ll mirror that:
                "id": -1,
                "uniq_id": int(node_id),
                "rank": r,
                "exclusive": False,
                "unit": "",
                "size": 1,
                "paths": { "containment": f"/{cluster_name}/{host}" },
            },
        )
        add_edge(edges, src=cluster_id, dst=node_id)

        # sockets
        for s in range(sockets):
            sock_name = f"socket{s}"
            sock_id = str(uniq); uniq += 1
            add_node(nodes,
                id_str=sock_id,
                meta={
                    "type": "socket",
                    "basename": "socket",
                    "name": sock_name,
                    "id": s,
                    "uniq_id": int(sock_id),
                    "rank": -1,
                    "exclusive": False,
                    "unit": "",
                    "size": 1,
                    "paths": { "containment": f"/{cluster_name}/{host}/{sock_name}" },
                },
            )
            add_edge(edges, src=node_id, dst=sock_id)

            # cores under socket
            for c in range(s*cores, (s+1)*cores):
                core_name = f"core{c}"
                core_id = str(uniq); uniq += 1
                add_node(nodes,
                    id_str=core_id,
                    meta={
                        "type": "core",
                        "basename": "core",
                        "name": core_name,
                        "id": c,
                        "uniq_id": int(core_id),
                        "rank": -1,
                        "exclusive": False,
                        "unit": "",
                        "size": 1,
                        "paths": {
                            "containment": f"/{cluster_name}/{host}/{sock_name}/{core_name}"
                        },
                    },
                )
                # IMPORTANT: make each core a child of the SOCKET (not a daisy chain)
                add_edge(edges, src=sock_id, dst=core_id)

    return { "graph": { "nodes": nodes, "edges": edges } }

def parse_hosts(args) -> List[str]:
    if args.nodes:
        return [h.strip() for h in args.nodes.split(",") if h.strip()]
    # auto-generate names like node0..node{N-1}
    return [f"{args.prefix}{i}" for i in range(args.nnodes)]

def main():
    ap = argparse.ArgumentParser(description="Generate JGF for cluster → node → socket → cores")
    ap.add_argument("--cluster-name", default="cluster0")
    ap.add_argument("--nodes", help="Comma-separated hostnames, e.g. n0,n1 (overrides --nnodes/--prefix)")
    ap.add_argument("--nnodes", type=int, default=1, help="Number of nodes if --nodes not given")
    ap.add_argument("--prefix", default="node", help="Hostname prefix if auto-generating")
    ap.add_argument("--sockets", type=int, default=1)
    ap.add_argument("--cores", type=int, default=12)
    ap.add_argument("--start-uniq-id", type=int, default=0)
    ap.add_argument("-o", "--out", default="-", help="Output file (default stdout)")
    args = ap.parse_args()

    hosts = parse_hosts(args)
    graph = gen_graph(
        cluster_name=args.cluster_name,
        hosts=hosts,
        sockets=args.sockets,
        cores=args.cores,
        start_uid=args.start_uniq_id,
    )

    data = json.dumps(graph, indent=2)
    if args.out == "-" or args.out == "/dev/stdout":
        print(data)
    else:
        with open(args.out, "w") as f:
            f.write(data)

if __name__ == "__main__":
    main()
