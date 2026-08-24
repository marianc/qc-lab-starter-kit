export interface ElectronicSignatureDto {
  id: number;
  entityName: string;
  entityId: number;
  signerUserId: number;
  signerUserTag: string;
  signatureMeaning: string;
  signingTimestamp: string;
  payloadSha256: string;
  signatureManifestText: string;
  clientIp: string;
  isValid: boolean;
}

export interface ElectronicSignatureVerificationDto {
  isSigned: boolean;
  isValid: boolean;
  statusMessage: string;
  signatures: ElectronicSignatureDto[];
}
