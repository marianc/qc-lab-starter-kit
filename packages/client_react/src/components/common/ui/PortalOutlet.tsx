import React from 'react';

interface Props {
  name: string;
}

const PortalOutlet: React.FC<Props> = ({ name }) => {
  return (
    <div id={`portal-outlet-${name}`} />
  );
};

export default PortalOutlet;
