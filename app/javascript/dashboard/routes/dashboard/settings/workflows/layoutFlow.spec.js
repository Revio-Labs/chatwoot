// @vitest-environment node
import { describe, it, expect } from 'vitest';
import fc from 'fast-check';
import { layoutFlow } from './layoutFlow';

const nodesEdgesArb = fc.integer({ min: 1, max: 12 }).chain(count => {
  const ids = Array.from({ length: count }, (_, i) => `n${i}`);
  const nodes = ids.map(id => ({
    id,
    type: 'flow',
    position: { x: 0, y: 0 },
    data: { type: 'send_message' },
  }));
  const edgeArb = fc.record({
    id: fc.string({ minLength: 1 }),
    source: fc.constantFrom(...ids),
    target: fc.constantFrom(...ids),
  });
  return fc.record({
    nodes: fc.constant(nodes),
    edges: fc.array(edgeArb, { maxLength: 15 }),
  });
});

describe('layoutFlow property', () => {
  it('returns the same nodes with finite, non-NaN positions', () => {
    fc.assert(
      fc.property(nodesEdgesArb, ({ nodes, edges }) => {
        const laid = layoutFlow(nodes, edges);
        expect(laid.length).toBe(nodes.length);
        expect(laid.map(n => n.id).sort()).toEqual(nodes.map(n => n.id).sort());
        laid.forEach(node => {
          expect(Number.isFinite(node.position.x)).toBe(true);
          expect(Number.isFinite(node.position.y)).toBe(true);
          expect(Number.isNaN(node.position.x)).toBe(false);
        });
      }),
      { numRuns: 150 }
    );
  });

  it('handles an empty node list without throwing', () => {
    expect(layoutFlow([], [])).toEqual([]);
  });
});
