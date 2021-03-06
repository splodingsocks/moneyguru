# Created By: Virgil Dupras
# Created On: 2006/02/21
# Copyright 2013 Hardcoded Software (http://www.hardcoded.net)

# This software is licensed under the "BSD" License as described in the "LICENSE" file, 
# which should be included with this package. The terms are also available at 
# http://www.hardcoded.net/licenses/bsd_license

import sys

from pytest import raises, mark

from ..path import *
from ..testutil import eq_

def pytest_funcarg__force_ossep(request):
    monkeypatch = request.getfuncargvalue('monkeypatch')
    monkeypatch.setattr(os, 'sep', '/')

def test_empty(force_ossep):
    path = Path('')
    eq_('',str(path))
    eq_(0,len(path))
    path = Path(())
    eq_('',str(path))
    eq_(0,len(path))

def test_single(force_ossep):
    path = Path('foobar')
    eq_('foobar',path)
    eq_(1,len(path))

def test_multiple(force_ossep):
    path = Path('foo/bar')
    eq_('foo/bar',path)
    eq_(2,len(path))

def test_init_with_tuple_and_list(force_ossep):
    path = Path(('foo','bar'))
    eq_('foo/bar',path)
    path = Path(['foo','bar'])
    eq_('foo/bar',path)

def test_init_with_invalid_value(force_ossep):
    try:
        path = Path(42)
        self.fail()
    except TypeError:
        pass

def test_access(force_ossep):
    path = Path('foo/bar/bleh')
    eq_('foo',path[0])
    eq_('foo',path[-3])
    eq_('bar',path[1])
    eq_('bar',path[-2])
    eq_('bleh',path[2])
    eq_('bleh',path[-1])

def test_slicing(force_ossep):
    path = Path('foo/bar/bleh')
    subpath = path[:2]
    eq_('foo/bar',subpath)
    assert isinstance(subpath,Path)

def test_deal_with_empty_components(force_ossep):
    """Keep ONLY a leading space, which means we want a leading slash.
    """
    eq_('foo//bar',str(Path(('foo','','bar'))))
    eq_('/foo/bar',str(Path(('','foo','bar'))))
    eq_('foo/bar',str(Path('foo/bar/')))

def test_old_compare_paths(force_ossep):
    eq_(Path('foobar'),Path('foobar'))
    eq_(Path('foobar/'),Path('foobar\\','\\'))
    eq_(Path('/foobar/'),Path('\\foobar\\','\\'))
    eq_(Path('/foo/bar'),Path('\\foo\\bar','\\'))
    eq_(Path('/foo/bar'),Path('\\foo\\bar\\','\\'))
    assert Path('/foo/bar') != Path('\\foo\\foo','\\')
    #We also have to test __ne__
    assert not (Path('foobar') != Path('foobar'))
    assert Path('/a/b/c.x') != Path('/a/b/c.y')

def test_old_split_path(force_ossep):
    eq_(Path('foobar'),('foobar',))
    eq_(Path('foo/bar'),('foo','bar'))
    eq_(Path('/foo/bar/'),('','foo','bar'))
    eq_(Path('\\foo\\bar','\\'),('','foo','bar'))

def test_representation(force_ossep):
    eq_("('foo', 'bar')",repr(Path(('foo','bar'))))

def test_add(force_ossep):
    eq_('foo/bar/bar/foo',Path(('foo','bar')) + Path('bar/foo'))
    eq_('foo/bar/bar/foo',Path('foo/bar') + 'bar/foo')
    eq_('foo/bar/bar/foo',Path('foo/bar') + ('bar','foo'))
    eq_('foo/bar/bar/foo',('foo','bar') + Path('bar/foo'))
    eq_('foo/bar/bar/foo','foo/bar' + Path('bar/foo'))
    #Invalid concatenation
    try:
        Path(('foo','bar')) + 1
        self.fail()
    except TypeError:
        pass

def test_path_slice(force_ossep):
    foo = Path('foo')
    bar = Path('bar')
    foobar = Path('foo/bar')
    eq_('bar',foobar[foo:])
    eq_('foo',foobar[:bar])
    eq_('foo/bar',foobar[bar:])
    eq_('foo/bar',foobar[:foo])
    eq_((),foobar[foobar:])
    eq_((),foobar[:foobar])
    abcd = Path('a/b/c/d')
    a = Path('a')
    b = Path('b')
    c = Path('c')
    d = Path('d')
    z = Path('z')
    eq_('b/c',abcd[a:d])
    eq_('b/c/d',abcd[a:d+z])
    eq_('b/c',abcd[a:z+d])
    eq_('a/b/c/d',abcd[:z])

def test_add_with_root_path(force_ossep):
    """if I perform /a/b/c + /d/e/f, I want /a/b/c/d/e/f, not /a/b/c//d/e/f
    """
    eq_('/foo/bar',str(Path('/foo') + Path('/bar')))

def test_create_with_tuple_that_have_slash_inside(force_ossep, monkeypatch):
    eq_(('','foo','bar'), Path(('/foo','bar')))
    monkeypatch.setattr(os, 'sep', '\\')
    eq_(('','foo','bar'), Path(('\\foo','bar')))

def test_auto_decode_os_sep(force_ossep, monkeypatch):
    """Path should decode any either / or os.sep, but always encode in os.sep.
    """
    eq_(('foo\\bar','bleh'),Path('foo\\bar/bleh'))
    monkeypatch.setattr(os, 'sep', '\\')
    eq_(('foo','bar/bleh'),Path('foo\\bar/bleh'))
    path = Path('foo/bar')
    eq_(('foo','bar'),path)
    eq_('foo\\bar',str(path))

def test_contains(force_ossep):
    p = Path(('foo','bar'))
    assert Path(('foo','bar','bleh')) in p
    assert Path(('foo','bar')) in p
    assert 'foo' in p
    assert 'bleh' not in p
    assert Path('foo') not in p

def test_windows_drive_letter(force_ossep):
    p = Path(('c:',))
    eq_('c:\\',str(p))

def test_root_path(force_ossep):
    p = Path('/')
    eq_('/',str(p))

def test_str_encodes_unicode_to_getfilesystemencoding(force_ossep):
    p = Path(('foo','bar\u00e9'))
    eq_('foo/bar\u00e9'.encode(sys.getfilesystemencoding()), p.tobytes())

def test_unicode(force_ossep):
    p = Path(('foo','bar\u00e9'))
    eq_('foo/bar\u00e9',str(p))

def test_str_repr_of_mix_between_non_ascii_str_and_unicode(force_ossep):
    u = 'foo\u00e9'
    encoded = u.encode(sys.getfilesystemencoding())
    p = Path((encoded,'bar'))
    print(repr(tuple(p)))
    eq_('foo\u00e9/bar'.encode(sys.getfilesystemencoding()), p.tobytes())

def test_Path_of_a_Path_returns_self(force_ossep):
    #if Path() is called with a path as value, just return value.
    p = Path('foo/bar')
    assert Path(p) is p

@mark.xfail(reason="pytest's capture mechanism is flaky, I have to investigate")
def test_log_unicode_errors(force_ossep, monkeypatch, capsys):
    # When an there's a UnicodeDecodeError on path creation, log it so it can be possible
    # to debug the cause of it.
    monkeypatch.setattr(sys, 'getfilesystemencoding', lambda: 'ascii')
    with raises(UnicodeDecodeError):
        Path(['', b'foo\xe9'])
    out, err = capsys.readouterr()
    assert repr(b'foo\xe9') in err

def test_has_drive_letter(monkeypatch):
    monkeypatch.setattr(os, 'sep', '\\')
    p = Path('foo\\bar')
    assert not p.has_drive_letter()
    p = Path('C:\\')
    assert p.has_drive_letter()
    p = Path('z:\\foo')
    assert p.has_drive_letter()

def test_remove_drive_letter(monkeypatch):
    monkeypatch.setattr(os, 'sep', '\\')
    p = Path('foo\\bar')
    eq_(p.remove_drive_letter(), Path('foo\\bar'))
    p = Path('C:\\')
    eq_(p.remove_drive_letter(), Path(''))
    p = Path('z:\\foo')
    eq_(p.remove_drive_letter(), Path('foo'))