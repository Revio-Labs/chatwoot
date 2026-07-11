/* global axios */
import ApiClient from './ApiClient';

class WorkflowsAPI extends ApiClient {
  constructor() {
    super('workflows', { accountScoped: true });
  }

  reorder(priorityOrder) {
    return axios.patch(`${this.url}/reorder`, {
      priority_order: priorityOrder,
    });
  }
}

export default new WorkflowsAPI();
