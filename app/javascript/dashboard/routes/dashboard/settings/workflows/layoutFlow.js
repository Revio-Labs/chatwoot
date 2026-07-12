import dagre from '@dagrejs/dagre';

// Fixed card footprint used for hierarchical layout. Matches FlowNode.vue.
export const NODE_WIDTH = 264;
export const NODE_HEIGHT = 116;

// Runs a left-to-right hierarchical layout (Intercom-style) over the flow and
// returns the nodes with computed positions. Pure — does not mutate inputs.
export const layoutFlow = (nodes, edges, direction = 'LR') => {
  if (!nodes.length) return nodes;

  const graph = new dagre.graphlib.Graph();
  graph.setDefaultEdgeLabel(() => ({}));
  graph.setGraph({
    rankdir: direction,
    ranksep: 110,
    nodesep: 44,
    marginx: 24,
    marginy: 24,
  });

  nodes.forEach(node => {
    graph.setNode(node.id, { width: NODE_WIDTH, height: NODE_HEIGHT });
  });
  edges.forEach(edge => {
    graph.setEdge(edge.source, edge.target);
  });

  dagre.layout(graph);

  return nodes.map(node => {
    const positioned = graph.node(node.id);
    return {
      ...node,
      position: {
        x: positioned.x - NODE_WIDTH / 2,
        y: positioned.y - NODE_HEIGHT / 2,
      },
    };
  });
};
