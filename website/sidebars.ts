import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Getting Started',
      collapsed: false,
      items: ['getting-started/installation', 'getting-started/quick-start'],
    },
    {
      type: 'category',
      label: 'Guide',
      collapsed: false,
      items: [
        'guide/mfarray',
        'guide/indexing',
        'guide/views',
        'guide/manipulation',
        'guide/arithmetic',
        'guide/math-and-stats',
        'guide/linalg',
        'guide/complex',
        'guide/image',
        'guide/audio',
        'guide/mlx',
      ],
    },
    'performance',
    'contributing',
  ],
  mappingSidebar: [
    'numpy-mapping/index',
    'numpy-mapping/creation',
    'numpy-mapping/conversion',
    'numpy-mapping/operation',
    'numpy-mapping/math',
    'numpy-mapping/stats',
    'numpy-mapping/linalg',
    'numpy-mapping/fft-and-audio',
    'numpy-mapping/interpolation',
    'numpy-mapping/image',
    'numpy-mapping/file-and-random',
  ],
};

export default sidebars;
