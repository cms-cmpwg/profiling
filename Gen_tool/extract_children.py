#!/usr/bin/env python3
"""
Extract immediate children of edm::stream::EDProducerAdaptorBase::doEvent
from a top-down profiling CSV file.
"""

import sys
import csv


def count_leading_spaces(line):
    """Count the number of leading spaces in a line."""
    count = 0
    for char in line:
        if char == ' ':
            count += 1
        else:
            break
    return count


def get_total_cpu_time(filename):
    """
    Get the total CPU time from the first data line.
    
    Args:
        filename: Path to the CSV file
    
    Returns:
        float: Total CPU time
    """
    with open(filename, 'r', encoding='utf-8') as f:
        # Skip the header lines
        for line in f:
            if line.startswith('Function Stack;'):
                break
        
        # Read the first data line (Total)
        for line in f:
            if line.strip():
                parts = line.split(';')
                if len(parts) >= 2:
                    try:
                        return float(parts[1])
                    except ValueError:
                        return 0.0
    return 0.0


def _safe_float(val):
    try:
        return float(val)
    except (ValueError, TypeError):
        return float('-inf')


def extract_immediate_children(filename, parent_function):
    """
    Extract all immediate children of a given parent function.
    
    Args:
        filename: Path to the CSV file
        parent_function: The function name to find children for
    
    Returns:
        Tuple[List[Tuple[str, str]], Optional[float]]: (children, parent_total_time)
    """
    children = []
    parent_indent = None
    found_parent = False
    parent_total_time = None
    unknown_block_active = False
    
    with open(filename, 'r', encoding='utf-8') as f:
        # Skip the header lines
        for line in f:
            if line.startswith('Function Stack;'):
                break
        
        # Process the data lines
        for line in f:
            # Skip empty lines
            if not line.strip():
                continue
            
            # Parse the line
            parts = line.split(';')
            if len(parts) < 4:
                continue
            
            function_stack = parts[0]
            total_time = parts[1]
            # self_time = parts[2]
            full_function = parts[3].strip()
            
            # Count leading spaces
            indent = count_leading_spaces(function_stack)
            
            # Check if this is the parent function we're looking for
            if parent_function in function_stack and not found_parent:
                parent_indent = indent
                found_parent = True
                try:
                    parent_total_time = float(total_time)
                except ValueError:
                    parent_total_time = None
                continue
            
            # If we found the parent, look for immediate children
            if found_parent and parent_indent is not None:
                # Immediate children have exactly one more level of indentation
                if indent == parent_indent + 1:
                    # If this child is the Unknown placeholder, don't add it;
                    # instead, activate a block to collect its immediate children.
                    if full_function.strip() == "[Unknown stack frame(s)]":
                        unknown_block_active = True
                    else:
                        children.append((full_function, total_time))
                        unknown_block_active = False
                # If we're inside an Unknown block, collect its immediate children
                elif indent == parent_indent + 2 and unknown_block_active:
                    children.append((full_function, total_time))
                # If we encounter a function at the same or lower level as the parent, we're done
                elif indent <= parent_indent:
                    break
                # If we encounter another sibling at the child level, toggle Unknown block appropriately
                elif indent == parent_indent + 1:
                    unknown_block_active = (full_function.strip() == "[Unknown stack frame(s)]")
                # For deeper levels beyond immediate children of Unknown, ignore
    
    return children, parent_total_time


def generate_html_table(children, parent_function, parent_total_time, total_cpu_time):
    """
    Generate an HTML table representation of the data.
    
    Args:
        children: List of (function_name, total_time) tuples
        parent_function: The parent function name
        parent_total_time: Total time of parent function
        total_cpu_time: Total CPU time
    
    Returns:
        str: HTML table as a string
    """
    html = []
    html.append('<!DOCTYPE html>')
    html.append('<html>')
    html.append('<head>')
    html.append('    <meta charset="UTF-8">')
    html.append('    <title>Function Profile Analysis</title>')
    html.append('    <style>')
    html.append('        body { font-family: Arial, sans-serif; margin: 20px; }')
    html.append('        h1, h2 { color: #333; }')
    html.append('        .info { background-color: #f0f0f0; padding: 10px; margin: 10px 0; border-radius: 4px; }')
    html.append('        table { border-collapse: collapse; width: 100%; margin: 20px 0; }')
    html.append('        th { background-color: #4CAF50; color: white; padding: 12px; text-align: left; }')
    html.append('        td { padding: 10px; border-bottom: 1px solid #ddd; }')
    html.append('        tr:hover { background-color: #f5f5f5; }')
    html.append('        .function-name { width: 400px; word-wrap: break-word; white-space: normal; }')
    html.append('        .numeric { text-align: right; font-family: monospace; }')
    html.append('    </style>')
    html.append('</head>')
    html.append('<body>')
    
    # Add title and info
    html.append('<h1>Function Profile Analysis</h1>')
    html.append(f'<div class="info">')
    html.append(f'    <h2>Parent Function: {parent_function}</h2>')
    html.append(f'    <p><strong>Total CPU Time:</strong> {total_cpu_time:.6f}</p>')
    if parent_total_time is not None:
        parent_percentage = (parent_total_time / total_cpu_time * 100) if total_cpu_time > 0 else 0
        html.append(f'    <p><strong>Parent Total Time:</strong> {parent_total_time:.6f} ({parent_percentage:.2f}% of total)</p>')
    html.append(f'    <p><strong>Number of Children:</strong> {len(children)}</p>')
    html.append('</div>')
    
    # Add table
    html.append('<table>')
    html.append('    <thead>')
    html.append('        <tr>')
    html.append('            <th class="function-name">Function</th>')
    html.append('            <th class="numeric">Total Time</th>')
    html.append('            <th class="numeric">% of Parent</th>')
    html.append('            <th class="numeric">% of Total</th>')
    html.append('        </tr>')
    html.append('    </thead>')
    html.append('    <tbody>')
    
    for full_function, total_time in children:
        html.append('        <tr>')
        html.append(f'            <td class="function-name">{full_function}</td>')
        try:
            time_val = float(total_time)
            html.append(f'            <td class="numeric">{time_val:.6f}</td>')
            
            if parent_total_time and parent_total_time > 0:
                pct_parent = time_val / parent_total_time * 100
                html.append(f'            <td class="numeric">{pct_parent:.2f}%</td>')
            else:
                html.append('            <td class="numeric">N/A</td>')
            
            if total_cpu_time > 0:
                pct_total = time_val / total_cpu_time * 100
                html.append(f'            <td class="numeric">{pct_total:.2f}%</td>')
            else:
                html.append('            <td class="numeric">N/A</td>')
        except ValueError:
            html.append(f'            <td class="numeric">{total_time}</td>')
            html.append('            <td class="numeric">N/A</td>')
            html.append('            <td class="numeric">N/A</td>')
        
        html.append('        </tr>')
    
    html.append('    </tbody>')
    html.append('</table>')
    html.append('</body>')
    html.append('</html>')
    
    return '\n'.join(html)


def main():
    if len(sys.argv) < 2:
        print("Usage: python extract_children.py <csv_file> [--html <output_file>]")
        sys.exit(1)
    
    filename = sys.argv[1]
    parent_function = "edm::stream::EDProducerAdaptorBase::doEvent"
    
    # Check for HTML output option
    html_output = None
    if len(sys.argv) >= 4 and sys.argv[2] == "--html":
        html_output = sys.argv[3]
    
    print(f"Extracting immediate children of: {parent_function}\n")
    
    # Get total CPU time
    total_cpu_time = get_total_cpu_time(filename)
    print(f"Total CPU time: {total_cpu_time}\n")
    
    children, parent_total_time = extract_immediate_children(filename, parent_function)
    
    if parent_total_time is not None:
        parent_percentage = (parent_total_time / total_cpu_time * 100) if total_cpu_time > 0 else 0
        print(f"{parent_function} total time: {parent_total_time:.6f} ({parent_percentage:.2f}% of total)\n")
    else:
        print(f"{parent_function} total time: N/A (function not found)\n")
    
    if not children:
        print("No children found.")
        return
    
    # Sort by total time (descending)
    children.sort(key=lambda item: _safe_float(item[1]), reverse=True)
    
    # Generate HTML output if requested
    if html_output:
        html_content = generate_html_table(children, parent_function, parent_total_time, total_cpu_time)
        with open(html_output, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"HTML table written to: {html_output}\n")
        return
    
    print(f"Found {len(children)} immediate children:\n")
    print("-" * 150)
    print(f"{'Function':<90} {'Total Time':>12} {'Pct of parent':>15} {'Pct of total':>15}")
    print("-" * 150)
    
    for full_function, total_time in children:
        try:
            time_val = float(total_time)
            if parent_total_time and parent_total_time > 0:
                pct_parent = time_val / parent_total_time * 100
                pct_parent_str = f"{pct_parent:>9.2f}%"
            else:
                pct_parent_str = "N/A"
            if total_cpu_time > 0:
                pct_total = time_val / total_cpu_time * 100
                pct_total_str = f"{pct_total:>9.2f}%"
            else:
                pct_total_str = "N/A"
            print(f"{full_function:<90} {time_val:>12.6f} {pct_parent_str:>15} {pct_total_str:>15}")
        except ValueError:
            print(f"{full_function:<90} {total_time:>12} {'N/A':>15} {'N/A':>15}")
    
    print("-" * 150)
    print(f"\nTotal: {len(children)} functions")


if __name__ == "__main__":
    main()
