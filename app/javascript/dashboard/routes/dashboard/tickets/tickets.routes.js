import { frontendURL } from '../../../helper/URLHelper';
import TicketsView from './TicketsView.vue';

const TICKET_PERMISSIONS = ['administrator', 'agent'];

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/tickets'),
      name: 'tickets_index',
      meta: {
        permissions: TICKET_PERMISSIONS,
      },
      component: TicketsView,
    },
  ],
};
