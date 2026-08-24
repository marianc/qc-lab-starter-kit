import React, { useState, useEffect } from 'react';
import type { ElectronicSignatureVerificationDto, ElectronicSignatureDto } from '@/types/electronicSignature';
import signaturesService from '@/services/signaturesService';
import { formatDate } from '@/lib/utils';
import styles from './SignatureManifestBlock.module.css';

interface Props {
  entityName: string;
  entityId: number;
}

const SignatureManifestBlock: React.FC<Props> = ({ entityName, entityId }) => {
  const [verification, setVerification] = useState<ElectronicSignatureVerificationDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedSig, setSelectedSig] = useState<ElectronicSignatureDto | null>(null);

  useEffect(() => {
    let isMounted = true;
    const fetchSignature = async () => {
      try {
        setLoading(true);
        const data = await signaturesService.verifyEntitySignature(entityName, entityId);
        if (isMounted) setVerification(data);
      } catch (err) {
        console.error('Failed to load electronic signature status:', err);
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    fetchSignature();
    return () => { isMounted = false; };
  }, [entityName, entityId]);

  if (loading) {
    return <div className={styles.signatureContainer}>Loading signature manifest...</div>;
  }

  if (!verification || !verification.isSigned) {
    return (
      <div className={styles.signatureContainer}>
        <div className={styles.signatureHeader}>
          <h4 className={styles.title}>Electronic Signature Manifest (21 CFR Part 11)</h4>
          <span className={`${styles.badge} ${styles.badgeUnsigned}`}>Not Signed</span>
        </div>
        <p style={{ margin: 0, color: '#6c757d', fontSize: '0.9rem' }}>
          This record has not been electronically signed yet.
        </p>
      </div>
    );
  }

  return (
    <div className={styles.signatureContainer}>
      <div className={styles.signatureHeader}>
        <h4 className={styles.title}>Electronic Signature Manifest (21 CFR Part 11)</h4>
        <span className={`${styles.badge} ${verification.isValid ? styles.badgeValid : styles.badgeInvalid}`}>
          {verification.isValid ? '✔ Signature Valid' : '⚠ Warning: Data Modified Post-Signature'}
        </span>
      </div>

      <div className={styles.signatureList}>
        {verification.signatures.map((sig) => (
          <div key={sig.id} className={styles.signatureCard}>
            <div className={styles.signatureMeta}>
              <div className={styles.metaItem}>
                <span className={styles.metaLabel}>Digitally Signed By</span>
                <span className={styles.metaValue}>{sig.signerUserTag}</span>
              </div>
              <div className={styles.metaItem}>
                <span className={styles.metaLabel}>Date / Time</span>
                <span className={styles.metaValue}>{formatDate(sig.signingTimestamp)} UTC</span>
              </div>
              <div className={styles.metaItem}>
                <span className={styles.metaLabel}>Signature Meaning</span>
                <span className={styles.metaValue}>{sig.signatureMeaning}</span>
              </div>
              <div className={styles.metaItem}>
                <span className={styles.metaLabel}>Status</span>
                <span className={styles.metaValue} style={{ color: sig.isValid ? '#137333' : '#c5221f' }}>
                  {sig.isValid ? 'Verified (SHA-256 Digest Match)' : 'Integrity Mismatch'}
                </span>
              </div>
            </div>

            <button 
              className={styles.inspectorButton} 
              onClick={() => setSelectedSig(sig)}
            >
              View Technical Audit Manifest & Hash
            </button>
          </div>
        ))}
      </div>

      {selectedSig && (
        <div className={styles.modalOverlay} onClick={() => setSelectedSig(null)}>
          <div className={styles.modalContent} onClick={(e) => e.stopPropagation()}>
            <div className={styles.modalHeader}>
              <h3>Technical Audit Inspector</h3>
              <button className={styles.closeButton} onClick={() => setSelectedSig(null)}>&times;</button>
            </div>
            <div className={styles.modalBody}>
              <div>
                <span className={styles.metaLabel}>Signature Manifest Text (§ 11.50)</span>
                <div className={styles.codeBlock}>{selectedSig.signatureManifestText}</div>
              </div>
              <div>
                <span className={styles.metaLabel}>Cryptographic SHA-256 Payload Hash</span>
                <div className={styles.hashText}>{selectedSig.payloadSha256}</div>
              </div>
              <div className={styles.signatureMeta}>
                <div className={styles.metaItem}>
                  <span className={styles.metaLabel}>Originating Client IP</span>
                  <span className={styles.metaValue}>{selectedSig.clientIp}</span>
                </div>
                <div className={styles.metaItem}>
                  <span className={styles.metaLabel}>System Entity Reference</span>
                  <span className={styles.metaValue}>{selectedSig.entityName} #{selectedSig.entityId}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SignatureManifestBlock;
