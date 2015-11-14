/*
 * dec2t2 - decode c2t2 encoded com file
 *
 * Copyright 2015 Joergen Ibsen
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))

static const uint8_t handler[] = {
	0x58, 0x35, 0x30, 0x32, 0x35, 0x30, 0x33, 0x50, 0x5F, 0x35,
	0x3A, 0x50, 0x29, 0x45, 0x6E, 0x2D, 0x77, 0x68, 0x50, 0x2C,
	0x51, 0x50, 0x35, 0x72, 0x48, 0x35, 0x3B, 0x54, 0x50, 0x2D,
	0x7B, 0x49, 0x50, 0x2D, 0x6B, 0x42, 0x2D, 0x6B, 0x54, 0x50,
	0x2D, 0x2A, 0x42, 0x50, 0x2D, 0x68, 0x63, 0x2D, 0x69, 0x5A,
	0x50, 0x35, 0x4F, 0x33, 0x35, 0x4A, 0x54, 0x50, 0x2D, 0x7A,
	0x61, 0x2D, 0x65, 0x42, 0x0D, 0x0A, 0x51, 0x50, 0x2D, 0x7B,
	0x58, 0x2C, 0x7D, 0x50, 0x2D, 0x5F, 0x73, 0x24, 0x44, 0x50,
	0x68, 0x3B, 0x79, 0x2D, 0x30, 0x6D, 0x2D, 0x28, 0x6A, 0x50,
	0x2D, 0x21, 0x5C, 0x50, 0x2D, 0x35, 0x4F, 0x2D, 0x4A, 0x41,
	0x50, 0x68, 0x5E, 0x24, 0x54, 0x5A, 0x53, 0x58, 0x53, 0x57,
	0x39, 0x24
};

struct state {
	const uint8_t *src;
	uint8_t *dst;
	size_t src_size;
	size_t dst_size;
	uint8_t tag;
	int tag_left;
};

/*
 * Get lowest two bits of tag in reverse order.
 */
static uint8_t
get_tag_bits(uint8_t tag)
{
	/* Lowest two bits reversed */
	return ((tag << 1) & 0x02) | ((tag >> 1) & 0x01);
}

/*
 * Get next 6-bit value.
 *
 * Returns 0 on success, 1 on end of data, -1 on error.
 */
static int
get_next_val(struct state *s, uint8_t *pv)
{
	uint8_t c;

	/* Skip whitespace */
	while (s->src_size > 0 && isspace(*s->src)) {
		++s->src;
		--s->src_size;
	}

	if (s->src_size == 0) {
		return 1;
	}

	c = *s->src++;
	--s->src_size;

	if (c >= '(' && c <= '-') {
		*pv = c - '(';
		return 0;
	}
	else if (c >= 'A' && c <= 'z') {
		*pv = c - 'A' + 6;
		return 0;
	}
	else if (c == '.') {
		return 1;
	}

	return -1;
}

/**
 * Decode data in state.
 *
 * Returns 0 on success, 1 on end of data, -1 on error.
 */
static int
decode(struct state *s)
{
	int res = -1;

	for (;;) {
		uint8_t c = 0;

		if (s->tag_left == 0) {
			res = get_next_val(s, &s->tag);
			if (res != 0) {
				return res;
			}
			s->tag_left = 6;
		}

		res = get_next_val(s, &c);
		if (res != 0) {
			return res;
		}

		c = (c << 2) | get_tag_bits(s->tag);
		s->tag >>= 2;
		s->tag_left -= 2;

		*s->dst++ = c;
		++s->dst_size;
	}
}

int main(int argc, char **argv)
{
	uint8_t src[256];
	uint8_t dst[256];
	struct state s;
	FILE *infile = NULL;
	FILE *outfile = NULL;
	size_t n_read;
	int res = EXIT_SUCCESS;

	if (argc < 3) {
		printf("Syntax: dec2t2 <infile> <outfile>\n");
		return EXIT_FAILURE;
	}

	infile = fopen(argv[1], "rb");
	if (infile == NULL) {
		printf("ERR: unable to open input file\n");
		res = EXIT_FAILURE;
		goto out;
	}

	outfile = fopen(argv[2], "w+b");
	if (outfile == NULL) {
		printf("ERR: unable to open output file\n");
		res = EXIT_FAILURE;
		goto out;
	}

	s.tag_left = 0;

	n_read = fread(src, 1, ARRAY_SIZE(handler), infile);

	if (n_read != ARRAY_SIZE(handler)
	 || memcmp(src, handler, ARRAY_SIZE(handler)) != 0) {
		printf("ERR: handler mismatch\n");
		res = EXIT_FAILURE;
		goto out;
	}

	while ((n_read = fread(src, 1, ARRAY_SIZE(src), infile)) > 0) {
		s.src = src;
		s.dst = dst;
		s.src_size = n_read;
		s.dst_size = 0;

		if (decode(&s) == -1) {
			printf("ERR: decode error\n");
			res = EXIT_FAILURE;
			goto out;
		}

		if (fwrite(dst, 1, s.dst_size, outfile) != s.dst_size) {
			printf("ERR: error writing\n");
			res = EXIT_FAILURE;
			goto out;
		}
	}

	printf("Everything appears to be okay.\n");

out:
	if (outfile != NULL) {
		fclose(outfile);
	}
	if (infile != NULL) {
		fclose(infile);
	}

	return res;
}
