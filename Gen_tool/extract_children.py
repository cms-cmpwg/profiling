#!/usr/bin/env python3
"""
Extract immediate children of edm::stream::EDProducerAdaptorBase::doEvent
from a top-down profiling CSV file.
"""

import sys
import os
import json
import re

_PRODUCE_RE = re.compile(r'::produce')


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

            # Once inside the parent's subtree, stop when we leave it
            if found_parent and parent_indent is not None:
                if indent <= parent_indent:
                    break
                # Collect any ::produce(...) function anywhere in the subtree
                if _PRODUCE_RE.search(full_function):
                    children.append((full_function, total_time))

    return children, parent_total_time


def _safe_percentage(numerator, denominator):
    if denominator and denominator > 0:
        return numerator / denominator * 100
    return None


def build_profile_data(children, parent_functions, parent_total_time, total_cpu_time, source_file, parent_csv_times=None):
    """
    Build a JSON-serializable profile payload.
    
    Args:
        children: List of dict rows with parent/function/total_time
        parent_functions: The parent function names
        parent_total_time: Total time of parent functions (sum of CSV field 2 per parent)
        total_cpu_time: Total CPU time
        parent_csv_times: Dict mapping parent function name -> time from CSV field 2
    
    Returns:
        dict: Profile payload
    """
    if parent_csv_times is None:
        parent_csv_times = {}
    rows = []
    for child in children:
        parent_function = child["parent_function"]
        full_function = child["function"]
        total_time = child["total_time"]
        try:
            time_val = float(total_time)
            pct_parent = _safe_percentage(time_val, parent_total_time)
            pct_total = _safe_percentage(time_val, total_cpu_time)
            rows.append({
                "parent_function": parent_function,
                "function": full_function,
                "total_time": time_val,
                "pct_of_parent": pct_parent,
                "pct_of_total": pct_total,
            })
        except ValueError:
            rows.append({
                "parent_function": parent_function,
                "function": full_function,
                "total_time": None,
                "total_time_raw": total_time,
                "pct_of_parent": None,
                "pct_of_total": None,
            })

    return {
        "source_file": source_file,
        "parent_functions": parent_functions,
        "summary": {
            "total_cpu_time": total_cpu_time,
            "parent_total_time": parent_total_time,
            "parent_pct_of_total": _safe_percentage(parent_total_time, total_cpu_time),
            "total_children_time": parent_total_time,
            "children_pct_of_total": _safe_percentage(parent_total_time, total_cpu_time),
            "children_pct_of_parent": _safe_percentage(parent_total_time, parent_total_time),
            "children_count": len(rows),
        },
        "parent_function_totals": [
            {
                "parent_function": parent_function,
                "children_total_time": parent_csv_times.get(parent_function, 0.0),
            }
            for parent_function in parent_functions
        ],
        "children": rows,
    }


def render_template_html(template_path, profile_data):
    """Render HTML by injecting profile JSON into a template page."""
    with open(template_path, 'r', encoding='utf-8') as f:
        template = f.read()

    data_json = json.dumps(profile_data, indent=2, ensure_ascii=False)
    # Keep JSON safe for embedding in a <script> tag.
    data_json = data_json.replace('</', '<\\/')
    return template.replace('__PROFILE_DATA_JSON__', data_json)


def parse_args(argv):
    """Parse command-line arguments."""
    if len(argv) < 2:
        return None

    args = {
        "filename": argv[1],
        "html_output": None,
        "json_output": None,
        "template_path": os.path.join(os.path.dirname(__file__), 'profile_report_template.html'),
    }

    i = 2
    while i < len(argv):
        token = argv[i]
        if token == '--html' and i + 1 < len(argv):
            args["html_output"] = argv[i + 1]
            i += 2
        elif token == '--json' and i + 1 < len(argv):
            args["json_output"] = argv[i + 1]
            i += 2
        elif token == '--template' and i + 1 < len(argv):
            args["template_path"] = argv[i + 1]
            i += 2
        else:
            print(f"Unknown or incomplete argument: {token}")
            return None

    return args


def main():
    args = parse_args(sys.argv)
    if not args:
        print(
            "Usage: python extract_children.py <csv_file> "
            "[--html <output_file>] [--json <output_file>] [--template <template_file>]"
        )
        sys.exit(1)

    filename = args["filename"]
    parent_functions = ["edm::stream::EDProducerAdaptorBase::doEvent", "edm::global::EDProducerBase::doEvent", "edm::one::EDProducerBase::doEvent","edm::limited::EDProducerBase::doEvent"]
    html_output = args["html_output"]
    json_output = args["json_output"]
    template_path = args["template_path"]
    
    global_children = []
    global_parent_total_time = 0.0
    parent_csv_times = {}
    # Get total CPU time
    total_cpu_time = get_total_cpu_time(filename)
    print(f"Total CPU time: {total_cpu_time}\n")

    for parent_function in parent_functions:
        print(f"Extracting immediate children of: {parent_function}\n")
        children, parent_total_time = extract_immediate_children(filename, parent_function)
        global_children.extend(
            {
                "parent_function": parent_function,
                "function": full_function,
                "total_time": total_time,
            }
            for full_function, total_time in children
        )
        csv_time = parent_total_time if parent_total_time is not None else 0.0
        global_parent_total_time += csv_time
        parent_csv_times[parent_function] = csv_time
    
    if global_parent_total_time is not None:
        parent_percentage = (global_parent_total_time / total_cpu_time * 100) if total_cpu_time > 0 else 0
        print(f"{parent_functions} total time: {global_parent_total_time:.6f} ({parent_percentage:.2f}% of total)\n")
    else:
        print(f"{parent_functions} total time: N/A (function not found)\n")
    
    
    # Sort by total time (descending)
    global_children.sort(key=lambda item: _safe_float(item["total_time"]), reverse=True)
    print(f"Found {len(global_children)} immediate children:\n")
    print("-" * 150)
    print(f"{'Total Time':>12} {'Pct of parent':>15} {'Pct of total':>15} {'Parent Function':<45} {'Function':<90}")
    print("-" * 150)
    
    for child in global_children:
        parent_function = child["parent_function"]
        full_function = child["function"]
        total_time = child["total_time"]
        try:
            time_val = float(total_time)
            if global_parent_total_time and global_parent_total_time > 0:
                pct_parent = time_val / global_parent_total_time * 100
                pct_parent_str = f"{pct_parent:>9.2f}%"
            else:
                pct_parent_str = "N/A"
            if total_cpu_time > 0:
                pct_total = time_val / total_cpu_time * 100
                pct_total_str = f"{pct_total:>9.2f}%"
            else:
                pct_total_str = "N/A"
            print(f"{time_val:>12.6f} {pct_parent_str:>15} {pct_total_str:>15} {parent_function:<45} {full_function:<90}")
        except ValueError:
            print(f"{total_time:>12} {'N/A':>15} {'N/A':>15} {parent_function:<45} {full_function:<90}")
    
    print("-" * 150)
    print(f"\nTotal: {len(global_children)} functions")
    print("\n")

    profile_data = build_profile_data(
        global_children,
        parent_functions,
        global_parent_total_time,
        total_cpu_time,
        source_file=filename,
        parent_csv_times=parent_csv_times,
    )

    if html_output and not json_output:
        json_output = os.path.splitext(html_output)[0] + '.json'

    if json_output:
        with open(json_output, 'w', encoding='utf-8') as f:
            json.dump(profile_data, f, indent=2, ensure_ascii=False)
            print(f"JSON data written to: {json_output}\n")

    if html_output:
        html_content = render_template_html(template_path, profile_data)
        with open(html_output, 'w', encoding='utf-8') as f:
            f.write(html_content)
            print(f"HTML report written to: {html_output}\n")
        return
    



if __name__ == "__main__":
    main()
