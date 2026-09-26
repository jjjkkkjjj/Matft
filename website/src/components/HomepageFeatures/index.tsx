import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  to: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Numpy-like API',
    to: '/docs/numpy-mapping',
    description: (
      <>
        Function names, arguments and behaviors follow Numpy, so you can port
        Python code almost line by line.
      </>
    ),
  },
  {
    title: 'Powerful indexing',
    to: '/docs/guide/indexing',
    description: (
      <>
        Slicing with <code>~&lt;</code>, negative, boolean and fancy indexing,
        and views sharing memory as in Numpy.
      </>
    ),
  },
  {
    title: 'Fast with Accelerate',
    to: '/docs/performance',
    description: (
      <>
        Math, statistics, linear algebra and FFT are backed by Apple&apos;s
        Accelerate framework.
      </>
    ),
  },
  {
    title: 'Complex numbers',
    to: '/docs/guide/complex',
    description: <>Arithmetic, math and indexing on complex arrays.</>,
  },
  {
    title: 'Image and audio',
    to: '/docs/guide/image',
    description: (
      <>
        OpenCV-compatible image processing, PIL / transformers-compatible
        preprocessing and librosa-compatible audio features.
      </>
    ),
  },
  {
    title: 'Works with MLX',
    to: '/docs/guide/mlx',
    description: (
      <>
        Zero-copy conversion between <code>MfArray</code> and{' '}
        <code>MLXArray</code>: preprocess with Matft, infer with MLX.
      </>
    ),
  },
];

function Feature({title, to, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4', styles.feature)}>
      <Heading as="h3">
        <Link to={to}>{title}</Link>
      </Heading>
      <p>{description}</p>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props) => (
            <Feature key={props.title} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
