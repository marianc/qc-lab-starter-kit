import React from 'react';
import type { SopDto } from '@/types/sop';
import { formatDate } from '@/lib/utils';
import styles from './SopsList.module.css';

interface Props {
  sops: SopDto[];
  onAddSop: () => void;
  onViewDetails: (sop: SopDto) => void;
}

const SopsList: React.FC<Props> = ({ sops, onAddSop, onViewDetails }) => {
  return (
    <div className={styles.container}>
      <div className={styles.headerRow}>
        <h3>Standard Operating Procedures (SOPs)</h3>
      </div>

      <div className={styles.actionRow}>
        <button onClick={onAddSop} className="action-button primary">
          Add new SOP
        </button>
      </div>

      <div className="table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              <th>Doc Code</th>
              <th>Title</th>
              <th>Active Version</th>
              <th>Date Created</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {sops.length === 0 ? (
              <tr>
                <td colSpan={5} className={styles.emptyCell}>No SOPs found for this norm.</td>
              </tr>
            ) : (
              sops.map((sop) => {
                const activeVersion = sop.versions.find(v => v.isActive);
                return (
                  <tr key={sop.id}>
                    <td>{sop.docCode}</td>
                    <td>{sop.title}</td>
                    <td>{activeVersion ? activeVersion.versionNumber : 'None'}</td>
                    <td>{formatDate(sop.dateCreated)}</td>
                    <td>
                      <button 
                        onClick={() => onViewDetails(sop)} 
                        className="action-button edit-button small-button"
                      >
                        Details
                      </button>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default SopsList;
