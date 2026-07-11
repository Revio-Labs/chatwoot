import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import TicketTypesAPI from '../../api/ticketTypes';
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
  getTicketTypes($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async function getTicketTypes({ commit }) {
    commit(types.SET_TICKET_TYPES_UI_FLAG, { isFetching: true });
    try {
      const response = await TicketTypesAPI.get();
      commit(types.SET_TICKET_TYPES, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_TICKET_TYPES_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createTicketType({ commit }, obj) {
    commit(types.SET_TICKET_TYPES_UI_FLAG, { isCreating: true });
    try {
      const response = await TicketTypesAPI.create(obj);
      commit(types.ADD_TICKET_TYPE, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_TICKET_TYPES_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_TICKET_TYPES_UI_FLAG, { isUpdating: true });
    try {
      const response = await TicketTypesAPI.update(id, updateObj);
      commit(types.EDIT_TICKET_TYPE, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_TICKET_TYPES_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_TICKET_TYPES_UI_FLAG, { isDeleting: true });
    try {
      await TicketTypesAPI.delete(id);
      commit(types.DELETE_TICKET_TYPE, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_TICKET_TYPES_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_TICKET_TYPES_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.SET_TICKET_TYPES]: MutationHelpers.set,
  [types.ADD_TICKET_TYPE]: MutationHelpers.create,
  [types.EDIT_TICKET_TYPE]: MutationHelpers.update,
  [types.DELETE_TICKET_TYPE]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
