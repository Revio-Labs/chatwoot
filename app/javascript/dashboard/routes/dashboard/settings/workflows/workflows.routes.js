import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import SettingsContent from '../Wrapper.vue';
import Index from './Index.vue';
import WorkflowBuilder from './WorkflowBuilder.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/workflows'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'workflows_index',
          component: Index,
          meta: { permissions: ['administrator'] },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/workflows'),
      component: SettingsContent,
      props: () => ({
        headerTitle: 'WORKFLOWS.HEADER',
        icon: 'git-fork',
        showBackButton: true,
      }),
      children: [
        {
          path: 'new',
          name: 'workflows_new',
          component: WorkflowBuilder,
          meta: { permissions: ['administrator'] },
        },
        {
          path: ':workflowId/edit',
          name: 'workflows_edit',
          component: WorkflowBuilder,
          meta: { permissions: ['administrator'] },
        },
      ],
    },
  ],
};
