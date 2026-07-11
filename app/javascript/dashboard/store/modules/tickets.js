import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import TicketsAPI from '../../api/tickets';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
  },
};

export const getters = {
  getTickets($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async function getTickets({ commit }, params = {}) {
    commit(types.SET_TICKETS_UI_FLAG, { isFetching: true });
    try {
      const response = await TicketsAPI.get(params);
      commit(types.SET_TICKETS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_TICKETS_UI_FLAG, { isFetching: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_TICKETS_UI_FLAG, { isUpdating: true });
    try {
      const response = await TicketsAPI.update(id, updateObj);
      commit(types.EDIT_TICKET, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_TICKETS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_TICKETS_UI_FLAG, { isDeleting: true });
    try {
      await TicketsAPI.delete(id);
      commit(types.DELETE_TICKET, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_TICKETS_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_TICKETS_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.SET_TICKETS]: MutationHelpers.set,
  [types.ADD_TICKET]: MutationHelpers.create,
  [types.EDIT_TICKET]: MutationHelpers.update,
  [types.DELETE_TICKET]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
