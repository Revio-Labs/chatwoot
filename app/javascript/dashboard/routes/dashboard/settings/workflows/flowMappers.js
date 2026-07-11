// Bidirectional mapping between the stored workflow flow ({nodes, edges}) that
// the Rails runtime consumes and the Vue Flow canvas representation.
//
// Storage node:  { id, type, position?, ...fields }
// Storage edge:  { from, to, match? }
// Vue Flow node: { id, type: 'flow', position, data: { type, ...fields } }
// Vue Flow edge: { id, source, target, label, data: { match } }

const AUTO_X = 120;
const AUTO_Y_STEP = 130;

export const edgeLabel = match => {
  if (!match) return '';
  if (match.type === 'button') return match.value ?? '';
  if (match.type === 'condition') return 'if…';
  if (match.type === 'fallback') return 'else';
  return '';
};

export const toVueFlow = (flow = {}) => {
  const storedNodes = Array.isArray(flow.nodes) ? flow.nodes : [];
  const storedEdges = Array.isArray(flow.edges) ? flow.edges : [];

  const nodes = storedNodes.map((node, index) => {
    const { id, position, ...fields } = node;
    return {
      id,
      type: 'flow',
      position: position || { x: AUTO_X, y: 60 + index * AUTO_Y_STEP },
      data: { ...fields },
    };
  });

  const edges = storedEdges.map((edge, index) => ({
    id: `e${index}-${edge.from}-${edge.to}`,
    source: edge.from,
    target: edge.to,
    label: edgeLabel(edge.match),
    data: { match: edge.match || null },
  }));

  return { nodes, edges };
};

const cleanData = data => {
  const out = {};
  Object.keys(data || {}).forEach(key => {
    const value = data[key];
    if (value === undefined || value === '' || value === null) return;
    out[key] = value;
  });
  return out;
};

export const toStorage = (nodes = [], edges = []) => {
  const storedNodes = nodes.map(node => {
    const { type, ...fields } = node.data || {};
    return {
      id: node.id,
      type,
      position: {
        x: Math.round(node.position?.x ?? 0),
        y: Math.round(node.position?.y ?? 0),
      },
      ...cleanData(fields),
    };
  });

  const storedEdges = edges.map(edge => {
    const base = { from: edge.source, to: edge.target };
    const match = edge.data?.match;
    return match ? { ...base, match } : base;
  });

  return { nodes: storedNodes, edges: storedEdges };
};
