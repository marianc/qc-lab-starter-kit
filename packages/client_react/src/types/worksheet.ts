export interface WorksheetTestItem {
  id: string; // client-side temporary unique id
  name: string;
  code: string;
  description?: string | null;
  measurement_unit: string;
  value_type: 'integer' | 'real' | 'boolean' | 'enum';
  enums?: string[] | null;
  is_array: boolean;
  for_certification: boolean;
  formula?: string | null;
  formula_dependencies?: string | null;
  nr_ord_calc: number;
  value?: any;
  code_related_arrays?: string | null;
  condition?: string | null;
  condition_note?: string | null;
  is_conforming_condition: boolean | null;
  conforming_results?: (boolean | null)[];
}

export const formatWorksheetValue = (item: { value?: any; value_type?: string; enums?: string[] | null; is_array?: boolean }): string => {
  if (item.value === null || item.value === undefined) return "-";
  
  if (item.value_type === 'enum' && item.enums && item.enums.length > 0) {
    if (Array.isArray(item.value)) {
      return item.value.map(v => {
        const num = Number(v);
        if (!isNaN(num) && num >= 1 && num <= item.enums!.length) {
          return item.enums![num - 1];
        }
        return String(v);
      }).join(", ");
    } else {
      const num = Number(item.value);
      if (!isNaN(num) && num >= 1 && num <= item.enums.length) {
        return item.enums[num - 1];
      }
      return String(item.value);
    }
  }

  if (item.value_type === 'boolean') {
    const formatBool = (v: any) => {
      if (v === true || v === 1 || v === '1' || v === 1.0 || v === 'true') return 'Yes';
      if (v === false || v === 0 || v === '0' || v === 0.0 || v === 'false') return 'No';
      return String(v);
    };
    if (Array.isArray(item.value)) {
      return item.value.map(formatBool).join(", ");
    }
    return formatBool(item.value);
  }

  if (Array.isArray(item.value)) {
    return item.value.join(", ");
  }
  return String(item.value);
};
