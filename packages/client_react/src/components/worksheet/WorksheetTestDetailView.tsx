import React from 'react';
import {
  DetailView,
  DetailViewHeader,
  DetailViewContent,
  DetailContainer,
  DetailColumn,
  DetailItem
} from '@/components/common/ui';
import type { WorksheetTestItem } from '@/types/worksheet';
import styles from './WorksheetTestDetailView.module.css';
import worksheetStyles from '@/pages/worksheet/WorksheetPage.module.css';

interface WorksheetTestDetailViewProps {
  item: WorksheetTestItem;
  onClose: (savedId?: string | null) => void;
  onEdit: () => void;
}

const WorksheetTestDetailView: React.FC<WorksheetTestDetailViewProps> = ({
  item,
  onClose,
  onEdit
}) => {
  return (
    <DetailView>
      <DetailViewHeader title={`Test Details: ${item.name}`} onBack={() => onClose(item.id)} />
      <DetailViewContent>
        <div className="page-container">
          <DetailContainer>
            <DetailColumn title="General Info">
              <DetailItem label="Name" value={item.name} />
              <DetailItem label="Code" value={item.code} />
              <DetailItem label="Description" value={item.description || '-'} />
              <DetailItem label="Measurement Unit" value={item.measurement_unit || '-'} />
              <DetailItem label="Value Type" value={item.value_type} />
              {item.value_type === 'enum' && item.enums && (
                <DetailItem 
                  label="Enum Options" 
                  value={item.enums.map((en, idx) => `[${idx + 1}] ${en}`).join('\n')} 
                />
              )}
              <DetailItem label="Is Array" value={item.is_array ? "Yes" : "No"} />
              {item.is_array && !item.formula && (
                <DetailItem label="Code Related Arrays" value={item.code_related_arrays || '-'} />
              )}
            </DetailColumn>
            <DetailColumn title="Formula & Certification">
              <DetailItem label="For Certification" value={item.for_certification ? "Yes" : "No"} />
              <DetailItem label="Formula" value={item.formula || '-'} />
              <DetailItem label="Formula Dependencies" value={item.formula_dependencies || '-'} />
              <DetailItem label="Calc Order (nr_ord_calc)" value={item.nr_ord_calc} />
              <DetailItem label="Condition" value={item.condition || '-'} />
              <DetailItem label="Condition Note" value={item.condition_note || '-'} />
              <DetailItem label="Conforming">
                {(!item.condition || item.condition.trim() === '') ? (
                  <span>-</span>
                ) : (
                  (() => {
                    const valArray = item.value !== null && item.value !== undefined ? (Array.isArray(item.value) ? item.value : [item.value]) : [];
                    const results = valArray.length === 0 
                      ? [false] 
                      : (item.conforming_results && item.conforming_results.length > 0 
                          ? item.conforming_results 
                          : [item.is_conforming_condition !== null && item.is_conforming_condition !== undefined ? item.is_conforming_condition : false]
                        );
                    return results.map((res: boolean | null, ridx: number) => {
                      const effectiveRes = res === null || res === undefined ? false : res;
                      const status = effectiveRes ? 'Pass' : 'Fail';
                      const statusClass = effectiveRes ? worksheetStyles.textSuccess : worksheetStyles.textDanger;
                      return (
                        <div key={ridx} className={statusClass}>
                          {status}
                        </div>
                      );
                    });
                  })()
                )}
              </DetailItem>
              <DetailItem label="Evaluated Value">
                {(() => {
                  if (item.value === null || item.value === undefined) return "-";
                  const vals = Array.isArray(item.value) ? item.value : [item.value];
                  if (vals.length === 0) return "-";
                  return vals.map((v, vidx) => {
                    let displayVal = "-";
                    if (v !== null && v !== undefined) {
                      if (item.value_type === 'enum' && item.enums && item.enums.length > 0) {
                        const num = Number(v);
                        if (!isNaN(num) && num >= 1 && num <= item.enums.length) {
                          displayVal = item.enums[num - 1];
                        } else {
                          displayVal = String(v);
                        }
                      } else if (item.value_type === 'boolean') {
                        if (v === true || v === 1 || v === '1' || v === 1.0 || v === 'true') displayVal = 'Yes';
                        else if (v === false || v === 0 || v === '0' || v === 0.0 || v === 'false') displayVal = 'No';
                        else displayVal = String(v);
                      } else {
                        displayVal = String(v);
                      }
                    }
                    return <div key={vidx}>{displayVal}</div>;
                  });
                })()}
              </DetailItem>
            </DetailColumn>
          </DetailContainer>

          <div className={styles.actionButtons}>
            <button onClick={onEdit} className="action-button edit-button">Edit</button>
          </div>
        </div>
      </DetailViewContent>
    </DetailView>
  );
};

export default WorksheetTestDetailView;
