// Registry of workflow node kinds. Drives the palette and the properties panel.
// `fields` describe the editable properties for each node type.
// Field types: text | textarea | number | select | buttons | json
export const NODE_TYPES = [
  {
    type: 'send_message',
    label: 'Send message',
    icon: 'i-lucide-message-square',
    color: 'text-n-slate-11',
    fields: [{ key: 'content', type: 'textarea', label: 'Message' }],
  },
  {
    type: 'send_buttons',
    label: 'Buttons',
    icon: 'i-lucide-square-mouse-pointer',
    color: 'text-n-teal-11',
    fields: [
      { key: 'content', type: 'textarea', label: 'Prompt' },
      { key: 'items', type: 'buttons', label: 'Buttons' },
    ],
  },
  {
    type: 'send_form',
    label: 'Form',
    icon: 'i-lucide-clipboard-list',
    color: 'text-n-teal-11',
    fields: [
      { key: 'content', type: 'textarea', label: 'Prompt' },
      { key: 'items', type: 'json', label: 'Fields (JSON)' },
      {
        key: 'ticket_type_id',
        type: 'number',
        label: 'Ticket type ID (optional)',
      },
    ],
  },
  {
    type: 'collect_input',
    label: 'Collect input',
    icon: 'i-lucide-text-cursor-input',
    color: 'text-n-teal-11',
    fields: [
      { key: 'content', type: 'textarea', label: 'Prompt' },
      { key: 'save_to', type: 'text', label: 'Save to variable' },
    ],
  },
  {
    type: 'set_attribute',
    label: 'Set attribute',
    icon: 'i-lucide-tag',
    color: 'text-n-amber-11',
    fields: [
      {
        key: 'scope',
        type: 'select',
        label: 'Scope',
        options: [
          { value: 'contact', label: 'Contact' },
          { value: 'conversation', label: 'Conversation' },
        ],
      },
      { key: 'key', type: 'text', label: 'Attribute key' },
      { key: 'value', type: 'text', label: 'Value' },
    ],
  },
  {
    type: 'branch',
    label: 'Branch',
    icon: 'i-lucide-git-branch',
    color: 'text-n-amber-11',
    fields: [],
  },
  {
    type: 'assign_team',
    label: 'Assign team',
    icon: 'i-lucide-users',
    color: 'text-n-amber-11',
    fields: [{ key: 'team_id', type: 'number', label: 'Team ID' }],
  },
  {
    type: 'assign_agent',
    label: 'Assign agent',
    icon: 'i-lucide-user',
    color: 'text-n-amber-11',
    fields: [{ key: 'agent_id', type: 'number', label: 'Agent ID' }],
  },
  {
    type: 'add_label',
    label: 'Add label',
    icon: 'i-lucide-bookmark',
    color: 'text-n-amber-11',
    fields: [{ key: 'label', type: 'text', label: 'Label' }],
  },
  {
    type: 'toggle_priority',
    label: 'Set priority',
    icon: 'i-lucide-flag',
    color: 'text-n-amber-11',
    fields: [
      {
        key: 'priority',
        type: 'select',
        label: 'Priority',
        options: [
          { value: 'low', label: 'Low' },
          { value: 'medium', label: 'Medium' },
          { value: 'high', label: 'High' },
          { value: 'urgent', label: 'Urgent' },
        ],
      },
    ],
  },
  {
    type: 'delay',
    label: 'Delay',
    icon: 'i-lucide-clock',
    color: 'text-n-slate-11',
    fields: [{ key: 'seconds', type: 'number', label: 'Seconds' }],
  },
  {
    type: 'captain_answer',
    label: 'Let Captain answer',
    icon: 'i-lucide-sparkles',
    color: 'text-n-teal-11',
    fields: [],
  },
  {
    type: 'handoff_workflow',
    label: 'Go to workflow',
    icon: 'i-lucide-git-fork',
    color: 'text-n-ruby-11',
    fields: [
      { key: 'workflow_definition_id', type: 'number', label: 'Workflow ID' },
    ],
  },
  {
    type: 'handoff_agent',
    label: 'Handoff to agent',
    icon: 'i-lucide-headset',
    color: 'text-n-ruby-11',
    fields: [],
  },
  {
    type: 'resolve',
    label: 'Resolve',
    icon: 'i-lucide-check-circle',
    color: 'text-n-ruby-11',
    fields: [],
  },
];

export const nodeTypeFor = type => NODE_TYPES.find(nt => nt.type === type);

export const defaultDataFor = type => {
  const def = nodeTypeFor(type);
  const data = { type };
  (def?.fields || []).forEach(field => {
    if (field.type === 'buttons' || field.type === 'json') data[field.key] = [];
    else if (field.type === 'number') data[field.key] = undefined;
    else data[field.key] = '';
  });
  return data;
};
