import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import WorkflowsAPI from '../../api/workflows';
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
  getWorkflows($state) {
    return $state.records;
  },
  getWorkflow: $state => id => {
    return $state.records.find(record => record.id === Number(id));
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async function getWorkflows({ commit }) {
    commit(types.SET_WORKFLOWS_UI_FLAG, { isFetching: true });
    try {
      const response = await WorkflowsAPI.get();
      commit(types.SET_WORKFLOWS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_WORKFLOWS_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createWorkflow({ commit }, workflowObj) {
    commit(types.SET_WORKFLOWS_UI_FLAG, { isCreating: true });
    try {
      const response = await WorkflowsAPI.create(workflowObj);
      commit(types.ADD_WORKFLOW, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_WORKFLOWS_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_WORKFLOWS_UI_FLAG, { isUpdating: true });
    try {
      const response = await WorkflowsAPI.update(id, updateObj);
      commit(types.EDIT_WORKFLOW, response.data);
      return response.data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_WORKFLOWS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_WORKFLOWS_UI_FLAG, { isDeleting: true });
    try {
      await WorkflowsAPI.delete(id);
      commit(types.DELETE_WORKFLOW, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_WORKFLOWS_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_WORKFLOWS_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.SET_WORKFLOWS]: MutationHelpers.set,
  [types.ADD_WORKFLOW]: MutationHelpers.create,
  [types.EDIT_WORKFLOW]: MutationHelpers.update,
  [types.DELETE_WORKFLOW]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
