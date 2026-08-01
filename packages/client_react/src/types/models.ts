export interface SelectableItem {
  id: number;
  name: string;
}

export interface IdDto {
  id: number;
}

export interface ToggleObsoleteDto {
  isObsolete: boolean;
  comments?: string | null;
}
