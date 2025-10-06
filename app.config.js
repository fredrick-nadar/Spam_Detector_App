module.exports = ({ config }) => {
  return {
    ...config,
    plugins: [
      ...(config.plugins || []),
      [
        'expo-build-properties',
        {
          android: {
            compileSdkVersion: 34,
            targetSdkVersion: 34,
            minSdkVersion: 24,
            buildToolsVersion: '34.0.0',
            usesCleartextTraffic: true, // For development
          },
        },
      ],
    ],
  };
};
