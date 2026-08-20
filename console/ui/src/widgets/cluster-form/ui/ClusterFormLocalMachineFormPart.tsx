import { FC } from 'react';
import DatabaseServersBlock from '@entities/cluster/database-servers-block';
import AuthenticationMethodFormBlock from '@entities/authentification-method-form-block';
import VipAddressBlock from '@entities/cluster/vip-address-block';
import LoadBalancersBlock from '@entities/cluster/load-balancers-block';
import { useWatch } from 'react-hook-form';
import { DATABASE_SERVERS_FIELD_NAMES } from '@entities/cluster/database-servers-block/model/const.ts';

const ClusterFormLocalMachineFormPart: FC = () => {
  const isHighAvailability = useWatch({ name: DATABASE_SERVERS_FIELD_NAMES.IS_HIGH_AVAILABILITY });

  return (
    <>
      <DatabaseServersBlock />
      <AuthenticationMethodFormBlock />
      {isHighAvailability ? <VipAddressBlock /> : null}
      <LoadBalancersBlock />
    </>
  );
};

export default ClusterFormLocalMachineFormPart;
