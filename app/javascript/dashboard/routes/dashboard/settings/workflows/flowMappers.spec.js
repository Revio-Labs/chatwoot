// @vitest-environment node
import { describe, it, expect } from 'vitest';
import fc from 'fast-check';
import { toVueFlow, toStorage, edgeLabel } from './flowMappers';

const NODE_TYPES = [
  'send_message',
  'send_buttons',
  'set_attribute',
  'branch',
  'resolve',
];

// Generates a coherent stored flow: unique node ids, edges between real nodes.
const storedFlowArb = fc.integer({ min: 1, max: 8 }).chain(count => {
  const ids = Array.from({ length: count }, (_, i) => `n${i}`);
  const nodes = ids.map((id, i) => ({
    id,
    type: NODE_TYPES[i % NODE_TYPES.length],
    content: `c${i}`,
  }));
  const edgeArb = fc.record({
    from: fc.constantFrom(...ids),
    to: fc.constantFrom(...ids),
    match: fc.option(
      fc.record({ type: fc.constant('button'), value: fc.string() }),
      { nil: undefined }
    ),
  });
  return fc.record({
    nodes: fc.constant(nodes),
    edges: fc.array(edgeArb, { maxLength: 10 }),
  });
});

const stripPosition = ({ position, ...rest }) => rest;

describe('flowMappers property', () => {
  it('round-trips storage -> vueflow -> storage preserving nodes and edges', () => {
    fc.assert(
      fc.property(storedFlowArb, flow => {
        const vf = toVueFlow(flow);
        const back = toStorage(vf.nodes, vf.edges);

        // node kind + fields preserved (ignoring the added position key)
        expect(back.nodes.map(stripPosition)).toEqual(
          flow.nodes.map(stripPosition)
        );

        // edges preserved (match kept only when present)
        const expectedEdges = flow.edges.map(e =>
          e.match
            ? { from: e.from, to: e.to, match: e.match }
            : { from: e.from, to: e.to }
        );
        expect(back.edges).toEqual(expectedEdges);
      }),
      { numRuns: 200 }
    );
  });

  it('every vueflow node carries a numeric position and the kind in data.type', () => {
    fc.assert(
      fc.property(storedFlowArb, flow => {
        const vf = toVueFlow(flow);
        vf.nodes.forEach(node => {
          expect(Number.isFinite(node.position.x)).toBe(true);
          expect(Number.isFinite(node.position.y)).toBe(true);
          expect(typeof node.data.type).toBe('string');
        });
      }),
      { numRuns: 100 }
    );
  });

  it('prettifies button edge labels by replacing underscores', () => {
    expect(edgeLabel({ type: 'button', value: 'trip_issue' })).toBe(
      'trip issue'
    );
    expect(edgeLabel({ type: 'fallback' })).toBe('else');
    expect(edgeLabel(null)).toBe('');
  });
});
