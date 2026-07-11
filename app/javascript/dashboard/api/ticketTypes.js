import ApiClient from './ApiClient';

class TicketTypesAPI extends ApiClient {
  constructor() {
    super('ticket_types', { accountScoped: true });
  }
}

export default new TicketTypesAPI();
