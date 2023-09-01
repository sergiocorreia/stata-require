program define assert_error
	cap `0'
	_assert c(rc), msg(`"Expected this to fail: `0'"')
	di as text "failed succesfully!"
end
