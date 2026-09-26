import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import CodeBlock from '@theme/CodeBlock';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import Heading from '@theme/Heading';

import styles from './index.module.css';

const numpyCode = `import numpy as np

a = np.arange(27).reshape(3, 3, 3)
b = a[1:3, :, 0]
c = np.sin(a) + a.T
a[a > 20] = 0`;

const matftCode = `import Matft

let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3, 3, 3])
let b = a[1~<3, Matft.all, 0]
let c = Matft.math.sin(a) + a.T
a[a > 20] = MfArray([0])`;

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link className="button button--secondary button--lg" to="/docs/intro">
            Get Started
          </Link>
          <Link className="button button--outline button--secondary button--lg" to="/docs/numpy-mapping">
            NumPy Mapping
          </Link>
        </div>
      </div>
    </header>
  );
}

function CodeComparison() {
  return (
    <section className={styles.comparison}>
      <div className="container">
        <Heading as="h2" className="text--center">
          Write Swift like Numpy
        </Heading>
        <div className="row">
          <div className="col col--6">
            <CodeBlock language="python" title="Numpy">
              {numpyCode}
            </CodeBlock>
          </div>
          <div className="col col--6">
            <CodeBlock language="swift" title="Matft">
              {matftCode}
            </CodeBlock>
          </div>
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title={siteConfig.title} description={siteConfig.tagline}>
      <HomepageHeader />
      <main>
        <CodeComparison />
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
