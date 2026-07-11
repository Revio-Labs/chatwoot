import ApiClient from './ApiClient';

class TicketsAPI extends ApiClient {
  constructor() {
    super('tickets', { accountScoped: true });
  }
}

export default new TicketsAPI();
