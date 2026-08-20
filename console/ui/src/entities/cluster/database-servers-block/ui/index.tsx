import { FC } from 'react';
import { Controller, useFieldArray, useFormContext } from 'react-hook-form';
import DatabaseServerBox from '@entities/cluster/database-servers-block/ui/DatabaseServerBox.tsx';
import { Box, Checkbox, FormControlLabel, Stack, Typography } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { DATABASE_SERVERS_FIELD_NAMES } from '@entities/cluster/database-servers-block/model/const.ts';

const createEmptyServer = () => ({
  [DATABASE_SERVERS_FIELD_NAMES.DATABASE_HOSTNAME]: '',
  [DATABASE_SERVERS_FIELD_NAMES.DATABASE_IP_ADDRESS]: '',
  [DATABASE_SERVERS_FIELD_NAMES.DATABASE_SSH_PORT]: '',
  [DATABASE_SERVERS_FIELD_NAMES.DATABASE_LOCATION]: '',
});

const DatabaseServersBlock: FC = () => {
  const { t } = useTranslation('clusters');
  const { control, getValues } = useFormContext();

  const { fields, replace } = useFieldArray({
    control,
    name: DATABASE_SERVERS_FIELD_NAMES.DATABASE_SERVERS,
  });

  const handleHaChange = (checked: boolean, onChange: (val: boolean) => void) => {
    onChange(checked);
    const currentServers = getValues(DATABASE_SERVERS_FIELD_NAMES.DATABASE_SERVERS) || [];
    if (checked) {
      const newServers = [...currentServers];
      while (newServers.length < 3) {
        newServers.push(createEmptyServer());
      }
      replace(newServers);
    } else {
      const server1 = currentServers[0] || createEmptyServer();
      replace([server1]);
    }
  };

  return (
    <Box>
      <Typography fontWeight="bold" marginBottom="8px">
        {t('databaseServers')}
      </Typography>
      <Controller
        name={DATABASE_SERVERS_FIELD_NAMES.IS_HIGH_AVAILABILITY}
        control={control}
        defaultValue={false}
        render={({ field: { value, onChange } }) => (
          <FormControlLabel
            control={
              <Checkbox
                checked={!!value}
                onChange={(e) => handleHaChange(e.target.checked, onChange)}
              />
            }
            label={t('highAvailability')}
          />
        )}
      />
      <Stack direction="column" gap="16px" justifyContent="center" alignItems="flex-start" sx={{ marginTop: '8px' }}>
        <Box display="flex" gap="16px" flexWrap="wrap" justifyContent="flex-start" alignItems="center">
          {fields.map((field, index) => (
            <DatabaseServerBox
              key={field.id}
              index={index}
            />
          ))}
        </Box>
      </Stack>
    </Box>
  );
};

export default DatabaseServersBlock;
