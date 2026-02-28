#!/usr/bin/env python3
"""
Enhanced transaction data generator for CI/CD pipeline.
Generates realistic transaction data with configurable parameters.
"""

import argparse
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import json
from pathlib import Path


class TransactionGenerator:
    """Generate realistic transaction data for testing and training."""

    def __init__(self, seed=None):
        """Initialize generator with optional random seed."""
        if seed:
            np.random.seed(seed)

        # Transaction templates by category
        self.templates = {
            'Baby Items': {
                'merchants': ['walmart', 'target', 'amazon', 'buybuybaby', 'babies r us'],
                'items': ['pampers diapers', 'baby lotion', 'wipes', 'formula', 'baby food',
                          'onesie', 'stroller', 'crib', 'pacifier', 'bottles'],
                'amount_range': (15, 150),
                'frequency': 0.08
            },
            'Groceries': {
                'merchants': ['whole foods', 'safeway', 'costco', 'trader joes', 'walmart',
                              'kroger', 'publix', 'albertsons'],
                'items': ['weekly shopping', 'grocery', 'bread milk eggs', 'produce',
                          'meat department', 'deli', 'bakery'],
                'amount_range': (30, 250),
                'frequency': 0.25
            },
            'Healthcare': {
                'merchants': ['cvs pharmacy', 'walgreens', 'rite aid', 'dr smith clinic',
                              'urgent care', 'hospital', 'dental office'],
                'items': ['prescription pickup', 'medicine', 'consultation fee', 'copay',
                          'lab work', 'x-ray', 'checkup'],
                'amount_range': (20, 500),
                'frequency': 0.10
            },
            'Transportation': {
                'merchants': ['uber', 'lyft', 'shell', 'chevron', 'bp', 'parking garage',
                              'metro', 'taxi'],
                'items': ['ride to', 'fuel', 'gas', 'parking fee', 'toll', 'transit pass'],
                'amount_range': (10, 100),
                'frequency': 0.15
            },
            'Utilities': {
                'merchants': ['pg&e', 'water company', 'comcast', 'verizon', 'att',
                              'spectrum', 'electric company'],
                'items': ['bill payment', 'monthly service', 'internet', 'phone service',
                          'cable'],
                'amount_range': (50, 300),
                'frequency': 0.08
            },
            'Entertainment': {
                'merchants': ['netflix', 'spotify', 'hulu', 'disney plus', 'amc theaters',
                              'concert venue', 'steam', 'playstation'],
                'items': ['monthly subscription', 'movie tickets', 'concert tickets',
                          'streaming service', 'game purchase'],
                'amount_range': (10, 150),
                'frequency': 0.12
            },
            'Restaurants': {
                'merchants': ['starbucks', 'chipotle', 'mcdonalds', 'olive garden',
                              'doordash', 'ubereats', 'pizza hut', 'subway'],
                'items': ['coffee', 'lunch', 'dinner', 'breakfast', 'delivery', 'takeout'],
                'amount_range': (8, 80),
                'frequency': 0.18
            },
            'Shopping': {
                'merchants': ['amazon', 'target', 'macys', 'nordstrom', 'best buy',
                              'home depot', 'ikea', 'nike'],
                'items': ['online order', 'clothing', 'shoes', 'electronics', 'furniture',
                          'home goods'],
                'amount_range': (20, 400),
                'frequency': 0.12
            }
        }

    def generate_narration(self, category):
        """Generate realistic transaction narration."""
        template = self.templates[category]
        merchant = np.random.choice(template['merchants'])
        item = np.random.choice(template['items'])

        # Different narration patterns
        patterns = [
            f"{merchant} {item}",
            f"{merchant} purchase {item}",
            f"{item} at {merchant}",
            f"{merchant} - {item}",
            f"payment to {merchant} for {item}"
        ]

        narration = np.random.choice(patterns)

        # Add reference number sometimes
        if np.random.random() > 0.7:
            ref = np.random.randint(1000, 9999)
            narration += f" ref#{ref}"

        return narration

    def generate_amount(self, category):
        """Generate realistic transaction amount."""
        min_amt, max_amt = self.templates[category]['amount_range']

        # Use log-normal distribution for more realistic amounts
        mean = (min_amt + max_amt) / 2
        sigma = (max_amt - min_amt) / 6
        amount = np.random.lognormal(np.log(mean), 0.5)

        # Clip to range
        amount = np.clip(amount, min_amt, max_amt)

        # Round to cents
        return round(amount, 2)

    def generate_date(self, start_date, days_back=30):
        """Generate random date within range."""
        days_offset = np.random.randint(0, days_back)
        return start_date - timedelta(days=days_offset)

    def generate_transactions(self, n_transactions, start_date=None):
        """
        Generate n transactions with realistic distribution.

        Args:
            n_transactions: Number of transactions to generate
            start_date: Start date for transactions (default: today)

        Returns:
            pandas DataFrame with transactions
        """
        if start_date is None:
            start_date = datetime.now()

        transactions = []

        # Calculate number of transactions per category based on frequency
        categories = list(self.templates.keys())
        frequencies = [self.templates[cat]['frequency'] for cat in categories]
        frequencies = np.array(frequencies) / sum(frequencies)

        category_counts = np.random.multinomial(n_transactions, frequencies)

        for category, count in zip(categories, category_counts):
            for _ in range(count):
                transaction = {
                    'narration': self.generate_narration(category),
                    'amount': self.generate_amount(category),
                    'date': self.generate_date(start_date),
                    'true_category': category  # For validation
                }
                transactions.append(transaction)

        # Add some unknown/ambiguous transactions (5%)
        n_unknown = int(n_transactions * 0.05)
        unknown_templates = [
            'payment to acme corp',
            'transfer to john doe',
            'check deposit #',
            'atm withdrawal',
            'venmo payment',
            'zelle transfer',
            'wire transfer',
            'cash deposit',
            'mobile deposit'
        ]

        for _ in range(n_unknown):
            template = np.random.choice(unknown_templates)
            transaction = {
                'narration': f"{template} {np.random.randint(1000, 9999)}",
                'amount': round(np.random.uniform(10, 500), 2),
                'date': self.generate_date(start_date),
                'true_category': 'Unknown'
            }
            transactions.append(transaction)

        # Create DataFrame and shuffle
        df = pd.DataFrame(transactions)
        df = df.sample(frac=1).reset_index(drop=True)

        # Format date
        df['date'] = df['date'].dt.strftime('%Y-%m-%d')

        return df

    def generate_streaming_batch(self, batch_size=100):
        """Generate a single batch for streaming simulation."""
        return self.generate_transactions(batch_size)

    def save_with_metadata(self, df, output_path):
        """Save transactions with metadata file."""
        # Save main CSV
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        df[['narration', 'amount', 'date']].to_csv(output_path, index=False)

        # Save metadata
        metadata = {
            'generated_at': datetime.now().isoformat(),
            'n_transactions': len(df),
            'date_range': {
                'start': df['date'].min(),
                'end': df['date'].max()
            },
            'category_distribution': df['true_category'].value_counts().to_dict(),
            'amount_stats': {
                'min': float(df['amount'].min()),
                'max': float(df['amount'].max()),
                'mean': float(df['amount'].mean()),
                'median': float(df['amount'].median()),
                'total': float(df['amount'].sum())
            }
        }

        metadata_path = output_path.parent / f"{output_path.stem}_metadata.json"
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)

        # Save with labels for validation
        validation_path = output_path.parent / f"{output_path.stem}_with_labels.csv"
        df.to_csv(validation_path, index=False)

        return output_path, metadata_path, validation_path


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description='Generate synthetic transaction data for NER training'
    )
    parser.add_argument(
        '--size', '-s',
        type=int,
        default=1000,
        help='Number of transactions to generate (default: 1000)'
    )
    parser.add_argument(
        '--output', '-o',
        type=str,
        default='data/sample_transactions.csv',
        help='Output CSV file path (default: data/sample_transactions.csv)'
    )
    parser.add_argument(
        '--seed',
        type=int,
        help='Random seed for reproducibility'
    )
    parser.add_argument(
        '--days-back',
        type=int,
        default=30,
        help='Number of days to spread transactions over (default: 30)'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Print detailed statistics'
    )

    args = parser.parse_args()

    # Generate data
    generator = TransactionGenerator(seed=args.seed)
    df = generator.generate_transactions(args.size)

    # Save with metadata
    main_file, meta_file, validation_file = generator.save_with_metadata(
        df, args.output
    )

    print(f"✓ Generated {len(df)} transactions")
    print(f"✓ Saved to: {main_file}")
    print(f"✓ Metadata: {meta_file}")
    print(f"✓ Validation: {validation_file}")

    if args.verbose:
        print("\n=== Statistics ===")
        print(f"Date range: {df['date'].min()} to {df['date'].max()}")
        print(f"Amount range: ${df['amount'].min():.2f} to ${df['amount'].max():.2f}")
        print(f"Total value: ${df['amount'].sum():.2f}")
        print("\nCategory distribution:")
        print(df['true_category'].value_counts().to_string())


if __name__ == '__main__':
    main()