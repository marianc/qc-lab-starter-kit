export interface NormDto {
  id: number;
  name: string;
  description: string | null;
  isObsolete: boolean;
  dateCreated: string;
  dateObsolete: string | null;
  commentsObsolete: string | null;
}

export interface CreateNormDto {
  name: string;
  description: string | null;
}

export interface UpdateNormDto {
  name: string;
  description: string | null;
}