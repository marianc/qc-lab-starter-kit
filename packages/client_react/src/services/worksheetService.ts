import apiClient from './apiClient';
import type { WorksheetTestItem } from '@/types/worksheet';

export const worksheetService = {
  async calculateWorksheet(items: WorksheetTestItem[]): Promise<WorksheetTestItem[]> {
    const minItems = items.map(i => ({
      code: i.code,
      formula: i.formula,
      is_array: i.is_array
    }));
    const res = await apiClient.post<Array<{ code: string; formula_dependencies?: string | null; nr_ord_calc: number }>>('api/worksheet/calculate-worksheet', { items: minItems });
    
    const updatedMap = new Map(res.data.map(r => [r.code.toLowerCase(), r]));
    const resultItems = items.map(item => {
      const match = updatedMap.get(item.code.toLowerCase());
      if (match) {
        return {
          ...item,
          formula_dependencies: match.formula_dependencies,
          nr_ord_calc: match.nr_ord_calc
        };
      }
      return item;
    });

    for (const match of res.data) {
      if (!resultItems.some(i => i.code.toLowerCase() === match.code.toLowerCase())) {
        resultItems.push({
          id: `dep_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          name: match.code,
          code: match.code,
          measurement_unit: '',
          value_type: 'real',
          is_array: false,
          for_certification: false,
          formula_dependencies: match.formula_dependencies,
          nr_ord_calc: match.nr_ord_calc,
          value: 1.0,
          condition_note: 'Pass',
          is_conforming_condition: true
        });
      }
    }

    return resultItems;
  },

  async calculateValues(items: WorksheetTestItem[]): Promise<WorksheetTestItem[]> {
    const minItems = items.map(i => ({
      code: i.code,
      formula: i.formula,
      formula_dependencies: i.formula_dependencies,
      nr_ord_calc: i.nr_ord_calc,
      value: i.value,
      is_array: i.is_array,
      code_related_arrays: i.code_related_arrays
    }));
    const res = await apiClient.post<Array<{ code: string; value?: any }>>('api/worksheet/calculate-values', { items: minItems });
    
    const updatedMap = new Map(res.data.map(r => [r.code.toLowerCase(), r]));
    return items.map(item => {
      const match = updatedMap.get(item.code.toLowerCase());
      if (match) {
        return {
          ...item,
          value: match.value
        };
      }
      return item;
    });
  },

  async calculateConformity(items: WorksheetTestItem[]): Promise<WorksheetTestItem[]> {
    const minItems = items.map(i => ({
      code: i.code,
      value: i.value,
      condition: i.condition
    }));
    const res = await apiClient.post<Array<{ code: string; is_conforming_condition?: boolean | null; conforming_results?: (boolean | null)[] }>>('api/worksheet/calculate-conformity', { items: minItems });
    
    const updatedMap = new Map(res.data.map(r => [r.code.toLowerCase(), r]));
    return items.map(item => {
      const match = updatedMap.get(item.code.toLowerCase());
      if (match) {
        return {
          ...item,
          is_conforming_condition: match.is_conforming_condition !== undefined ? match.is_conforming_condition : null,
          conforming_results: match.conforming_results !== undefined ? match.conforming_results : item.conforming_results
        };
      }
      return item;
    });
  },

  async calculate(items: WorksheetTestItem[]): Promise<WorksheetTestItem[]> {
    const step1 = await this.calculateWorksheet(items);
    const step2 = await this.calculateValues(step1);
    return await this.calculateConformity(step2);
  },

  async importFormEval(formEvalId: number): Promise<WorksheetTestItem[]> {
    const res = await apiClient.get<WorksheetTestItem[]>(`api/worksheet/import/${formEvalId}`);
    const items = res.data;
    return await this.calculateConformity(items);
  },

  async getImportableFormEvals(): Promise<Array<{ id: number; label: string }>> {
    const res = await apiClient.get<Array<{ id: number; label: string }>>('api/worksheet/importable-evals');
    return res.data;
  },

  async validateFormula(formula: string | null, currentCode: string, isArray: boolean, items: WorksheetTestItem[]): Promise<void> {
    const res = await apiClient.post<{ valid: boolean; msg?: string }>('api/worksheet/validate/formula', {
      formula,
      current_code: currentCode,
      is_array: isArray,
      items: items.map(item => ({
        code: item.code,
        is_array: item.is_array
      }))
    });
    if (!res.data.valid) {
      throw new Error(res.data.msg || 'Invalid formula');
    }
  }
};

export default worksheetService;
