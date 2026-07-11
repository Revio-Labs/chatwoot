import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/ticket-types'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'ticket_types_index',
          component: Index,
          meta: { permissions: ['administrator'] },
        },
      ],
    },
  ],
};
