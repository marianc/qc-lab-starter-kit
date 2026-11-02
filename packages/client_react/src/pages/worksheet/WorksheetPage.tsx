import React, { useState, useEffect, useRef } from 'react';
import WorksheetTestDialog from '@/components/worksheet/WorksheetTestDialog';
import WorksheetTestDetailView from '@/components/worksheet/WorksheetTestDetailView';
import WorksheetValuesDetailView from '@/components/worksheet/WorksheetValuesDetailView';
import SelectFormEvalDialog from '@/components/worksheet/SelectFormEvalDialog';
import FormulaDialog from '@/components/formGroups/forms/FormulaDialog';
import { DragHandle } from '@/components/common/ui';
import { ConfirmationDialog, NotificationDialog } from '@/components/common';
import type { WorksheetTestItem } from '@/types/worksheet';
import { formatWorksheetValue } from '@/types/worksheet';
import worksheetService from '@/services/worksheetService';
import styles from './WorksheetPage.module.css';

const WorksheetPage: React.FC = () => {
  const [items, setItems] = useState<WorksheetTestItem[]>([]);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [showValuesDetailView, setShowValuesDetailView] = useState(false);
  const [showSelectEvalDialog, setShowSelectEvalDialog] = useState(false);
  const [importableFormEvals, setImportableFormEvals] = useState<Array<{ id: number; label: string }>>([]);
  const [lastSelectedEvalId, setLastSelectedEvalId] = useState<number | null>(null);
  const [editingItem, setEditingItem] = useState<WorksheetTestItem | null>(null);
  const [selectedItemForDetail, setSelectedItemForDetail] = useState<WorksheetTestItem | null>(null);
  const [lastEditedItemId, setLastEditedItemId] = useState<string | null>(null);
  const [showFormulaDialog, setShowFormulaDialog] = useState(false);
  const [selectedFormula, setSelectedFormula] = useState<string | null>(null);
  const [draggedItemIndex, setDraggedItemIndex] = useState<number | null>(null);
  const [isDragHandleActive, setIsDragHandleActive] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [itemToDelete, setItemToDelete] = useState<WorksheetTestItem | null>(null);
  const [showConfirmDeleteDialog, setShowConfirmDeleteDialog] = useState(false);
  const [dependencyDeleteError, setDependencyDeleteError] = useState<React.ReactNode | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const calculateItems = async (currentItems: WorksheetTestItem[]) => {
    if (currentItems.length === 0) {
      setItems([]);
      return;
    }
    setLoading(true);
    try {
      const calculated = await worksheetService.calculate(currentItems);
      const list = Array.isArray(calculated) ? calculated : [];
      const itemsWithIds = list.map((it, idx) => ({
        ...it,
        id: it.id || `calc_${Date.now()}_${idx}_${Math.random().toString(36).substr(2, 9)}`
      }));
      setItems(itemsWithIds);
      setError(null);
    } catch (err: any) {
      setError(err.message || 'Calculation error');
    } finally {
      setLoading(false);
    }
  };

  const calculateValuesAndConformity = async (currentItems: WorksheetTestItem[]) => {
    if (currentItems.length === 0) {
      setItems([]);
      return;
    }
    setLoading(true);
    try {
      const step2 = await worksheetService.calculateValues(currentItems);
      const step3 = await worksheetService.calculateConformity(step2);
      const list = Array.isArray(step3) ? step3 : [];
      const itemsWithIds = list.map((it, idx) => ({
        ...it,
        id: it.id || `calc_${Date.now()}_${idx}_${Math.random().toString(36).substr(2, 9)}`
      }));
      setItems(itemsWithIds);
      setError(null);
    } catch (err: any) {
      setError(err.message || 'Calculation error');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveItem = async (savedItem: WorksheetTestItem) => {
    let newItems = [...items];
    const index = newItems.findIndex(i => i.id === savedItem.id);
    if (index >= 0) {
      newItems[index] = savedItem;
    } else {
      newItems.push(savedItem);
    }
    setShowAddDialog(false);
    setEditingItem(null);
    await calculateItems(newItems);
    setLastEditedItemId(savedItem.id);
  };

  const handleDeleteClick = (item: WorksheetTestItem) => {
    setError(null);
    const dependentItems = items.filter(i => {
      if (i.id === item.id) return false;
      if (!i.formula || i.formula.trim() === '') return false;
      if (i.formula_dependencies) {
        const deps = i.formula_dependencies.split(',').map(d => d.trim().toLowerCase());
        if (deps.includes(item.code.toLowerCase())) return true;
      }
      const codeLower = item.code.toLowerCase();
      const formulaLines = i.formula.split('\n').filter(line => !line.trim().startsWith('//')).join('\n').toLowerCase();
      if (formulaLines.includes(`[${codeLower}]`) || formulaLines.includes(`[[${codeLower}]]`)) {
        return true;
      }
      return false;
    });

    if (dependentItems.length > 0) {
      const errorContent = (
        <div>
          <p>Cannot delete &apos;{item.name} ({item.code})&apos; because it is used as a dependency in:</p>
          <ul style={{ margin: '10px 0 0 20px', paddingLeft: 0 }}>
            {dependentItems.map((dep, idx) => (
              <li key={idx}>{dep.name} ({dep.code})</li>
            ))}
          </ul>
        </div>
      );
      setDependencyDeleteError(errorContent);
      return;
    }

    setItemToDelete(item);
    setShowConfirmDeleteDialog(true);
  };

  const handleConfirmDelete = async () => {
    if (itemToDelete) {
      const newItems = items.filter(i => i.id !== itemToDelete.id);
      setItemToDelete(null);
      setShowConfirmDeleteDialog(false);
      await calculateItems(newItems);
    }
  };

  const handleViewDetails = (item: WorksheetTestItem) => {
    setSelectedItemForDetail(item);
  };

  const handleEditFromDetail = () => {
    if (selectedItemForDetail) {
      setEditingItem(selectedItemForDetail);
      setSelectedItemForDetail(null);
      setShowAddDialog(true);
    }
  };

  const handleDragStart = (index: number) => {
    if (!isDragHandleActive) return;
    setDraggedItemIndex(index);
  };

  const handleDragEnter = (index: number) => {
    if (draggedItemIndex === null || draggedItemIndex === index) return;
    const newItems = [...items];
    const draggedItem = newItems[draggedItemIndex];
    newItems.splice(draggedItemIndex, 1);
    newItems.splice(index, 0, draggedItem);
    setItems(newItems);
    setDraggedItemIndex(index);
  };

  const handleDragEnd = async () => {
    setDraggedItemIndex(null);
    setIsDragHandleActive(false);
    await calculateItems(items);
  };

  const serializeNodeToString = (node: Node, indentLevel = 0): string => {
    const indent = '  '.repeat(indentLevel);
    
    if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent || '';
      return text ? `${indent}${text}\n` : '';
    }
    
    if (node.nodeType === Node.CDATA_SECTION_NODE) {
      const val = node.nodeValue || '';
      return `${indent}<![CDATA[${val}]]>\n`;
    }
    
    if (node.nodeType === Node.ELEMENT_NODE) {
      const el = node as Element;
      let result = `${indent}<${el.tagName}`;
      
      if (el.attributes && el.attributes.length > 0) {
        for (let i = 0; i < el.attributes.length; i++) {
          const attr = el.attributes[i];
          result += ` ${attr.name}="${attr.value}"`;
        }
      }
      
      const children = Array.from(el.childNodes);
      if (children.length === 0) {
        result += ' />\n';
        return result;
      }
      
      const hasOnlyText = children.every(c => c.nodeType === Node.TEXT_NODE || c.nodeType === Node.CDATA_SECTION_NODE);
      if (hasOnlyText && children.length === 1) {
        const child = children[0];
        if (child.nodeType === Node.CDATA_SECTION_NODE) {
          const val = child.nodeValue || '';
          result += `><![CDATA[${val}]]></${el.tagName}>\n`;
        } else {
          const text = child.textContent || '';
          if (text === '') {
            result += ' />\n';
          } else {
            result += `>${text}</${el.tagName}>\n`;
          }
        }
        return result;
      }
      
      result += '>\n';
      for (const child of children) {
        result += serializeNodeToString(child, indentLevel + 1);
      }
      result += `${indent}</${el.tagName}>\n`;
      return result;
    }
    
    if (node.nodeType === Node.DOCUMENT_NODE) {
      let result = '<?xml version="1.0" encoding="utf-8"?>\n';
      const children = Array.from(node.childNodes);
      for (const child of children) {
        result += serializeNodeToString(child, indentLevel);
      }
      return result;
    }
    
    return '';
  };

  const handleSaveXml = () => {
    const xmlDoc = document.implementation.createDocument(null, 'WorksheetPlayground', null);
    const root = xmlDoc.documentElement;
    const testsEl = xmlDoc.createElement('Tests');

    items.forEach(item => {
      const testEl = xmlDoc.createElement('Test');

      const appendChild = (tag: string, val: any) => {
        const el = xmlDoc.createElement(tag);
        if (val !== null && val !== undefined) {
          const strVal = Array.isArray(val) ? val.join(',') : String(val);
          if (strVal !== '') {
            if (tag === 'Formula' || tag === 'Description' || tag === 'ConditionNote' || tag === 'Condition') {
              el.appendChild(xmlDoc.createCDATASection(strVal));
            } else {
              el.textContent = strVal;
            }
          }
        }
        testEl.appendChild(el);
      };

      appendChild('Name', item.name);
      appendChild('Code', item.code);
      appendChild('Description', item.description);
      appendChild('MeasurementUnit', item.measurement_unit);
      appendChild('ValueType', item.value_type);
      
      if (item.enums && item.enums.length > 0) {
        const enumsEl = xmlDoc.createElement('Enums');
        item.enums.forEach(en => {
          const eEl = xmlDoc.createElement('Enum');
          eEl.textContent = en;
          enumsEl.appendChild(eEl);
        });
        testEl.appendChild(enumsEl);
      }

      appendChild('IsArray', item.is_array);
      appendChild('ForCertification', item.for_certification);
      appendChild('Formula', item.formula);
      appendChild('FormulaDependencies', item.formula_dependencies);
      appendChild('NrOrdCalc', item.nr_ord_calc);

      const valuesEl = xmlDoc.createElement('Values');
      if (item.value !== null && item.value !== undefined) {
        const valArray = Array.isArray(item.value) ? item.value : [item.value];
        const confArray = Array.isArray(item.conforming_results) && item.conforming_results.length > 0 
          ? item.conforming_results 
          : (item.is_conforming_condition !== undefined && item.is_conforming_condition !== null ? [item.is_conforming_condition] : []);

        valArray.forEach((v: any, idx: number) => {
          const itemEl = xmlDoc.createElement('Item');
          
          const valEl = xmlDoc.createElement('Value');
          if (v !== null && v !== undefined) {
            valEl.textContent = String(v);
          }
          itemEl.appendChild(valEl);

          const confEl = xmlDoc.createElement('IsConformingCondition');
          const hasCondition = item.condition && item.condition.trim() !== '';
          if (hasCondition) {
            const isNullVal = v === null || v === undefined || (typeof v === 'string' && v.trim() === '');
            let confVal: boolean;
            if (isNullVal) {
              confVal = false;
            } else {
              confVal = confArray[idx] !== undefined && confArray[idx] !== null ? confArray[idx] : false;
            }
            confEl.textContent = String(confVal);
          } else {
            confEl.textContent = '';
          }
          itemEl.appendChild(confEl);

          valuesEl.appendChild(itemEl);
        });
      }
      testEl.appendChild(valuesEl);

      appendChild('CodeRelatedArrays', item.code_related_arrays);
      appendChild('Condition', item.condition);
      appendChild('ConditionNote', item.condition_note);

      const confTestEl = xmlDoc.createElement('IsConformingCondition');
      const hasCondition = item.condition && item.condition.trim() !== '';
      if (hasCondition) {
        const valArray = item.value !== null && item.value !== undefined ? (Array.isArray(item.value) ? item.value : [item.value]) : [];
        if (valArray.length === 0) {
          confTestEl.textContent = 'false';
        } else {
          const confArray = Array.isArray(item.conforming_results) && item.conforming_results.length > 0 
            ? item.conforming_results 
            : (item.is_conforming_condition !== undefined && item.is_conforming_condition !== null ? [item.is_conforming_condition] : []);
          
          let allConforming = true;
          valArray.forEach((v: any, idx: number) => {
            const isNullVal = v === null || v === undefined || (typeof v === 'string' && v.trim() === '');
            let confVal: boolean;
            if (isNullVal) {
              confVal = false;
            } else {
              confVal = confArray[idx] !== undefined && confArray[idx] !== null ? confArray[idx] : false;
            }
            if (!confVal) {
              allConforming = false;
            }
          });
          confTestEl.textContent = allConforming ? 'true' : 'false';
        }
      }
      testEl.appendChild(confTestEl);

      testsEl.appendChild(testEl);
    });

    root.appendChild(testsEl);

    const xmlString = serializeNodeToString(xmlDoc);
    const blob = new Blob([xmlString], { type: 'application/xml' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `worksheet_playground_${Date.now()}.qcf.xml`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleLoadXml = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (event) => {
      try {
        const text = event.target?.result as string;
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(text, 'application/xml');
        const testElements = xmlDoc.getElementsByTagName('Test');
        
        const loadedItems: WorksheetTestItem[] = [];

        for (let i = 0; i < testElements.length; i++) {
          const tEl = testElements[i];
          const getVal = (tag: string) => tEl.getElementsByTagName(tag)[0]?.textContent || null;
          const getBool = (tag: string) => getVal(tag) === 'true';

          const name = getVal('Name') || '';
          const code = getVal('Code') || '';
          const description = getVal('Description');
          const measurement_unit = getVal('MeasurementUnit') || '';
          const value_type = (getVal('ValueType') || 'real') as any;

          const enumEls = tEl.getElementsByTagName('Enum');
          let enums: string[] | null = null;
          if (enumEls.length > 0) {
            enums = [];
            for (let j = 0; j < enumEls.length; j++) {
              if (enumEls[j].textContent) enums.push(enumEls[j].textContent!);
            }
          }

          const is_array = getBool('IsArray');
          const for_certification = getBool('ForCertification');
          const formula = getVal('Formula');
          const formula_dependencies = getVal('FormulaDependencies');
          const nr_ord_calc = parseInt(getVal('NrOrdCalc') || '0', 10);
          
          const valuesEl = tEl.getElementsByTagName('Values')[0];
          let value: any = null;
          let conforming_results: (boolean | null)[] = [];
          let is_conforming_condition: boolean | null = null;

          if (valuesEl) {
            const itemEls = valuesEl.getElementsByTagName('Item');
            if (itemEls.length > 0) {
              const parsedVals: any[] = [];
              const parsedConfs: (boolean | null)[] = [];
              for (let j = 0; j < itemEls.length; j++) {
                const itemEl = itemEls[j];
                const valText = itemEl.getElementsByTagName('Value')[0]?.textContent;
                const confText = itemEl.getElementsByTagName('IsConformingCondition')[0]?.textContent;

                if (valText !== null && valText !== undefined) {
                  const trimmed = valText.trim();
                  if (trimmed !== '' && !isNaN(Number(trimmed))) {
                    parsedVals.push(Number(trimmed));
                  } else {
                    parsedVals.push(trimmed);
                  }
                } else {
                  parsedVals.push(null);
                }

                if (confText === 'true' || confText === '1') {
                  parsedConfs.push(true);
                } else if (confText === 'false' || confText === '0') {
                  parsedConfs.push(false);
                } else {
                  parsedConfs.push(null);
                }
              }

              if (is_array) {
                value = parsedVals;
                conforming_results = parsedConfs;
                is_conforming_condition = parsedConfs.length > 0 ? parsedConfs.every(c => c === true) : null;
              } else {
                value = parsedVals.length > 0 ? parsedVals[0] : null;
                is_conforming_condition = parsedConfs.length > 0 ? parsedConfs[0] : null;
                conforming_results = is_conforming_condition !== null ? [is_conforming_condition] : [];
              }
            } else {
              // Legacy structure: direct <Value> elements inside <Values>
              const valEls = valuesEl.getElementsByTagName('Value');
              const parsedVals: any[] = [];
              for (let j = 0; j < valEls.length; j++) {
                const text = valEls[j].textContent;
                if (text !== null && text !== undefined) {
                  const trimmed = text.trim();
                  if (trimmed !== '' && !isNaN(Number(trimmed))) {
                    parsedVals.push(Number(trimmed));
                  } else {
                    parsedVals.push(trimmed);
                  }
                }
              }
              if (is_array) {
                value = parsedVals;
              } else {
                value = parsedVals.length > 0 ? parsedVals[0] : null;
              }

              const confStr = getVal('IsConformingCondition');
              if (confStr === 'true' || confStr === '1') {
                is_conforming_condition = true;
              } else if (confStr === 'false' || confStr === '0') {
                is_conforming_condition = false;
              } else {
                is_conforming_condition = null;
              }
              conforming_results = parsedVals.map(() => is_conforming_condition);
            }
          } else {
            value = is_array ? [] : null;
            const confStr = getVal('IsConformingCondition');
            if (confStr === 'true' || confStr === '1') {
              is_conforming_condition = true;
            } else if (confStr === 'false' || confStr === '0') {
              is_conforming_condition = false;
            } else {
              is_conforming_condition = null;
            }
            conforming_results = [];
          }

          const code_related_arrays = getVal('CodeRelatedArrays');
          const condition = getVal('Condition');
          const condition_note = getVal('ConditionNote') || '';

          loadedItems.push({
            id: `test_${Date.now()}_${i}_${Math.random().toString(36).substr(2, 9)}`,
            name,
            code,
            description,
            measurement_unit,
            value_type,
            enums,
            is_array,
            for_certification,
            formula,
            formula_dependencies,
            nr_ord_calc,
            value,
            code_related_arrays,
            condition,
            condition_note,
            is_conforming_condition,
            conforming_results
          });
        }

        if (loadedItems.length > 0) {
          setItems(loadedItems);
          setError(null);
        }
      } catch (err) {
        setError('Failed to parse XML file');
      }
    };
    reader.readAsText(file);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleImportFormEvalClick = async () => {
    setLoading(true);
    try {
      const evals = await worksheetService.getImportableFormEvals();
      setImportableFormEvals(evals || []);
      setShowSelectEvalDialog(true);
    } catch (err: any) {
      setError(err.message || 'Failed to fetch importable form evaluations');
    } finally {
      setLoading(false);
    }
  };

  const handleSelectFormEval = async (formEvalId: number) => {
    setLastSelectedEvalId(formEvalId);
    setShowSelectEvalDialog(false);
    setLoading(true);
    try {
      const imported = await worksheetService.importFormEval(formEvalId);
      const list = Array.isArray(imported) ? imported : [];
      const itemsWithIds = list.map((it, idx) => ({
        ...it,
        id: it.id || `import_${Date.now()}_${idx}_${Math.random().toString(36).substr(2, 9)}`
      }));
      setItems(itemsWithIds);
      setError(null);
    } catch (err: any) {
      setError(err.message || 'Failed to import form eval');
    } finally {
      setLoading(false);
    }
  };

  const formatValueDisplay = (item: WorksheetTestItem) => {
    return formatWorksheetValue(item);
  };

  const getFormattedValues = (item: WorksheetTestItem): string[] => {
    if (item.value === null || item.value === undefined) return ["-"];
    const vals = Array.isArray(item.value) ? item.value : [item.value];
    if (vals.length === 0) return ["-"];

    return vals.map(v => {
      if (v === null || v === undefined) return "-";
      if (item.value_type === 'enum' && item.enums && item.enums.length > 0) {
        const num = Number(v);
        if (!isNaN(num) && num >= 1 && num <= item.enums.length) {
          return item.enums[num - 1];
        }
        return String(v);
      }
      if (item.value_type === 'boolean') {
        if (v === true || v === 1 || v === '1' || v === 1.0 || v === 'true') return 'Yes';
        if (v === false || v === 0 || v === '0' || v === 0.0 || v === 'false') return 'No';
        return String(v);
      }
      return String(v);
    });
  };

  const getTestNameDisplay = (item: WorksheetTestItem) => {
    const isCalc = !(!item.formula || item.formula.trim() === '');
    const paramSuffix = isCalc ? "" : "!";
    const typeName = item.is_array ? `[${item.value_type}]` : item.value_type;
    return `${item.name}${paramSuffix} (${item.code}, ${typeName})`;
  };

  const getForCertificationDisplay = (item: WorksheetTestItem) => {
    if (!item.for_certification) return "No";
    const hasCondition = item.condition && item.condition.trim() !== '';
    return hasCondition ? "Yes" : "Yes?";
  };

  return (
    <div className="page-container">
      <h2 className="page-title">Worksheet Playground</h2>
      <p className={styles.subtitle}>Experiment with form design and live formula calculations in-memory without saving to the database.</p>
      
      <div className={styles.actions}>
        <button onClick={() => { setEditingItem(null); setShowAddDialog(true); }} className="action-button primary">
          Add Test
        </button>
        <button onClick={() => setShowValuesDetailView(true)} className="action-button primary" disabled={items.length === 0}>
          Edit Values
        </button>
        <button onClick={handleSaveXml} className="action-button secondary" disabled={items.length === 0}>
          Save Worksheet (.qcf.xml)
        </button>
        <button onClick={() => fileInputRef.current?.click()} className="action-button secondary">
          Load Worksheet (.qcf.xml)
        </button>
        <input 
          type="file" 
          ref={fileInputRef} 
          onChange={handleLoadXml} 
          accept=".xml,.qcf.xml" 
          style={{ display: 'none' }} 
        />
        <button onClick={handleImportFormEvalClick} className="action-button secondary">
          Import from Form Eval ID
        </button>
      </div>

      <SelectFormEvalDialog
        open={showSelectEvalDialog}
        options={importableFormEvals}
        selectedId={lastSelectedEvalId}
        onSelect={handleSelectFormEval}
        onClose={() => setShowSelectEvalDialog(false)}
      />

      {loading && <div className={styles.loadingMessage}>Processing...</div>}
      {error && <div className={styles.errorMessage}>{error}</div>}

      <table className="data-table">
        <thead>
          <tr>
            <th>Test</th>
            <th>Unit</th>
            <th>Dependencies</th>
            <th>Code Array Columns</th>
            <th>Value</th>
            <th>Condition</th>
            <th>Conforming</th>
            <th>For Certification</th>
            <th>Actions</th>
            <th className="drag-handle-col"></th>
          </tr>
        </thead>
        <tbody>
          {items.length === 0 ? (
            <tr>
              <td colSpan={10} className={styles.emptyRow}>No tests added yet. Click "Add Test" or import from a measurement to start experimenting.</td>
            </tr>
          ) : (
            items.map((item, index) => (
              <tr 
                key={item.id} 
                className={`${item.id === lastEditedItemId ? 'highlighted-row' : ''} ${draggedItemIndex === index ? 'dragging' : ''}`}
                draggable={true}
                onDragStart={() => handleDragStart(index)}
                onDragOver={(e) => e.preventDefault()}
                onDragEnter={() => handleDragEnter(index)}
                onDragEnd={handleDragEnd}
              >
                <td>{getTestNameDisplay(item)}</td>
                <td>{item.measurement_unit || "-"}</td>
                <td 
                  onClick={() => { if (item.formula) { setSelectedFormula(item.formula); setShowFormulaDialog(true); } }} 
                  className={item.formula ? styles.clickable : ""}
                >
                  {item.formula_dependencies || "-"}
                </td>
                <td>{item.code_related_arrays || "-"}</td>
                <td>
                  {getFormattedValues(item).map((val, vidx) => (
                    <div key={vidx}>{val}</div>
                  ))}
                </td>
                <td 
                  onClick={() => { if (item.condition) { setSelectedFormula(item.condition); setShowFormulaDialog(true); } }} 
                  className={item.condition ? styles.clickable : ""}
                >
                  {item.condition_note || "-"}
                </td>
                <td>
                  {item.condition && item.condition.trim() !== '' ? (
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
                        const statusClass = effectiveRes ? styles.textSuccess : styles.textDanger;
                        return (
                          <div key={ridx} className={statusClass}>
                            {status}
                          </div>
                        );
                      });
                    })()
                  ) : (
                    <span>-</span>
                  )}
                </td>
                <td>{getForCertificationDisplay(item)}</td>
                <td>
                  <div className={styles.rowActions}>
                    <button onClick={() => handleViewDetails(item)} className="action-button edit-button small-button">Details</button>
                    <button onClick={() => { setEditingItem(item); setShowAddDialog(true); }} className="action-button edit-button small-button">Edit</button>
                    <button onClick={() => handleDeleteClick(item)} className="action-button delete-button small-button">Delete</button>
                  </div>
                </td>
                <td>
                  <DragHandle 
                    onMouseDown={() => setIsDragHandleActive(true)} 
                    onMouseUp={() => setIsDragHandleActive(false)} 
                  />
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>

      <ConfirmationDialog
        open={showConfirmDeleteDialog}
        title="Delete Test"
        message={`Are you sure you want to delete test "${itemToDelete?.name} (${itemToDelete?.code})"?`}
        onConfirm={handleConfirmDelete}
        onCancel={() => { setShowConfirmDeleteDialog(false); setItemToDelete(null); }}
      />

      <NotificationDialog
        open={!!dependencyDeleteError}
        title="Cannot Delete Test"
        message={dependencyDeleteError || ""}
        onClose={() => setDependencyDeleteError(null)}
      />

      <WorksheetTestDialog
        open={showAddDialog}
        item={editingItem}
        items={items}
        onSave={handleSaveItem}
        onClose={() => { setShowAddDialog(false); setEditingItem(null); }}
      />

      {showValuesDetailView && (
        <WorksheetValuesDetailView
          items={items}
          onClose={() => setShowValuesDetailView(false)}
          onSave={async (updated) => {
            setShowValuesDetailView(false);
            await calculateValuesAndConformity(updated);
          }}
        />
      )}

      {selectedItemForDetail && (
        <WorksheetTestDetailView
          item={selectedItemForDetail}
          onClose={(savedId) => {
            setSelectedItemForDetail(null);
            if (savedId) {
              setLastEditedItemId(savedId);
            }
          }}
          onEdit={handleEditFromDetail}
        />
      )}

      {showFormulaDialog && (
        <FormulaDialog 
          formula={selectedFormula} 
          onClose={() => setShowFormulaDialog(false)} 
        />
      )}
    </div>
  );
};

export default WorksheetPage;
